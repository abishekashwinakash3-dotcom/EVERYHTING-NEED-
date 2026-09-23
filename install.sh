#!/usr/bin/env bash
# EVERYTHING-NEED — Claude Code setup installer
# Usage: ./install.sh --all | --plugins | --skills | --mcp [--dry-run] [--yes]
set -uo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
WORK_DIR="${TMPDIR:-/tmp}/ainstall-$$"
# Scan reports must OUTLIVE this run — the user is told to read them.
SCAN_DIR="$CLAUDE_DIR/skill-scans"
# Backups must NOT live under skills/ — Claude Code loads every directory
# there that has a SKILL.md, so a "<name>.bak" would be a live duplicate skill.
BACKUP_DIR="$CLAUDE_DIR/skill-backups"

DO_PLUGINS=0; DO_SKILLS=0; DO_MCP=0; DRY=0; YES=0
FAILED=(); INSTALLED=(); SKIPPED=(); REVIEW=()

# ---------- output ----------
if [ -t 1 ]; then R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[34m'; BOLD=$'\e[1m'; N=$'\e[0m'
else R=""; G=""; Y=""; B=""; BOLD=""; N=""; fi
say()  { printf '%s\n' "$*"; }
head_(){ printf '\n%s%s══ %s%s\n' "$BOLD" "$B" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
err()  { printf '  %s✗%s %s\n' "$R" "$N" "$*"; }
step() { printf '  %s·%s %s\n' "$B" "$N" "$*"; }
dry()  { printf '  %s[dry]%s %s\n' "$Y" "$N" "$*"; }

usage() {
  cat <<USAGE
EVERYTHING-NEED installer

  ./install.sh --all         Install plugins + skills + MCP servers
  ./install.sh --plugins     Claude Code plugin marketplaces only
  ./install.sh --skills      Skill bundles only (security-scanned first)
  ./install.sh --mcp         MCP servers only

  --dry-run   Show what would happen, change nothing
  --yes       Don't prompt. HIGH/CRITICAL-risk skills are SKIPPED, never
              auto-installed — that decision always needs a human.
  --help      This message
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all) DO_PLUGINS=1; DO_SKILLS=1; DO_MCP=1 ;;
    --plugins) DO_PLUGINS=1 ;;
    --skills)  DO_SKILLS=1 ;;
    --mcp)     DO_MCP=1 ;;
    --dry-run) DRY=1 ;;
    --yes|-y)  YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 2 ;;
  esac; shift
done
if [ $((DO_PLUGINS+DO_SKILLS+DO_MCP)) -eq 0 ]; then usage; exit 0; fi

cleanup() { [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"; }
trap cleanup EXIT

# ---------- preflight ----------
head_ "Preflight"
MISSING=0
need() {
  if command -v "$1" >/dev/null 2>&1; then ok "$1 — $(command -v "$1")"
  else err "$1 not found — $2"; MISSING=1; fi
}
need git    "install from https://git-scm.com"
need claude "install: npm i -g @anthropic-ai/claude-code"
if [ "$DO_MCP" = 1 ] || [ "$DO_SKILLS" = 1 ]; then
  need node "install Node 18+ from https://nodejs.org"
fi
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${NODE_MAJOR:-0}" -lt 18 ]; then err "Node $NODE_MAJOR is too old — need 18+"; MISSING=1; fi
fi
[ "$MISSING" = 1 ] && { err "Fix the above, then re-run."; exit 1; }

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  ok "gh authenticated"
else
  warn "gh not authenticated — your OWN repos/forks can't be cloned"
  say  "      the installer falls back to upstream sources automatically,"
  say  "      but run 'gh auth login' to get YOUR forks (docs/01)"
fi

if [ "$YES" != 1 ] && [ "$DRY" != 1 ]; then
  say ""
  say "This installs into: ${BOLD}$CLAUDE_DIR${N}"
  printf 'Continue? [y/N] '
  read -r reply </dev/tty || reply=""
  case "$reply" in [yY]*) ;; *) say "Aborted."; exit 0 ;; esac
fi

mkdir -p "$WORK_DIR" "$SKILLS_DIR" "$SCAN_DIR" "$BACKUP_DIR"

# ============================================================
# Shared: clone a repo, falling back to its upstream
# ============================================================
# Your forks need gh auth; the upstreams are public and clone anonymously.
# Trying the fork first keeps any customisation you've made.
CLONED_FROM=""
clone_repo() {
  local primary="$1" fallback="$2" dest="$3"
  if git clone --depth 1 --quiet "https://github.com/$primary" "$dest" 2>/dev/null; then
    CLONED_FROM="$primary"; return 0
  fi
  if [ -n "$fallback" ]; then
    rm -rf "$dest"
    if git clone --depth 1 --quiet "https://github.com/$fallback" "$dest" 2>/dev/null; then
      CLONED_FROM="$fallback"; return 0
    fi
  fi
  CLONED_FROM=""; return 1
}

# ============================================================
# PLUGINS
# ============================================================
auth_hint_shown=0
gh_auth_hint() {
  [ "$auth_hint_shown" = 1 ] && return 0
  auth_hint_shown=1
  warn "GitHub auth needed to clone that source:"
  say  "        gh auth login     # then: ./install.sh --plugins"
}

add_marketplace() {
  # add_marketplace <primary-repo> <upstream-fallback|""> <label>
  local primary="$1" fallback="$2" label="$3" out
  step "marketplace: $label"
  if [ "$DRY" = 1 ]; then dry "claude plugin marketplace add $primary"; return 0; fi

  for repo in "$primary" "$fallback"; do
    [ -z "$repo" ] && continue
    out="$(claude plugin marketplace add "$repo" 2>&1)"
    if claude plugin marketplace list 2>/dev/null | grep -qi "$(basename "$repo")"; then
      [ "$repo" != "$primary" ] && warn "used upstream $repo (fork unavailable)"
      ok "$repo"; return 0
    fi
    case "$out" in
      *"authentication failed"*|*"could not read Username"*|*"terminal prompts disabled"*)
        [ "$repo" = "$primary" ] && [ -n "$fallback" ] && { step "fork needs auth — trying upstream"; continue; }
        gh_auth_hint ;;
    esac
  done

  err "could not add $label"
  printf '%s\n' "$out" | grep -viE '^\s*$' | head -3 | sed 's/^/        /'
  FAILED+=("marketplace:$primary"); return 1
}

install_plugin() {
  local plugin="$1" label="$2" out
  step "plugin: $label"
  if [ "$DRY" = 1 ]; then dry "claude plugin install $plugin"; return 0; fi
  if out="$(claude plugin install "$plugin" --scope user -y 2>&1)"; then
    ok "installed $plugin"; INSTALLED+=("plugin:$plugin")
  else
    err "failed $plugin"
    printf '%s\n' "$out" | grep -viE '^\s*$' | head -3 | sed 's/^/        /'
    say "        retry interactively: claude plugin install $plugin"
    FAILED+=("plugin:$plugin")
  fi
}

if [ "$DO_PLUGINS" = 1 ]; then
  head_ "Plugins"
  add_marketplace "affaan-m/ECC" "" "ECC (agents + skills + hooks)" \
    && install_plugin "ecc@ecc" "ECC operator layer"
  add_marketplace "abishekashwinakash3-dotcom/scroll-craft" "nateherkai/scroll-craft" "nateherk design" \
    && install_plugin "nateherk-design@nateherk" "scroll-craft landing pages"
fi

# ============================================================
# SKILLS  (security-gated)
# ============================================================
SCAN_OK=0

# Returns one of: SAFE|LOW|MEDIUM|HIGH|CRITICAL|SCAN_FAILED|NOT_A_SKILL
#
# The scanner exits 0 even for HIGH/CRITICAL risk, so the EXIT CODE MUST NOT
# be used as the gate — the verdict is parsed out of the report. A crash
# produces no verdict at all, which is reported as SCAN_FAILED rather than
# being treated as a pass: a skill could otherwise crash the parser on purpose
# to slip through (see docs/06).
risk_of() {
  local target="$1" report="$2" r
  [ -f "$target/SKILL.md" ] || { printf 'NOT_A_SKILL'; return 0; }
  npx --yes -p claude-skill-antivirus@latest claude-skill-av \
      --scan-only -v "$target" >"$report" 2>&1 || true
  r="$(grep -m1 'Risk Level:' "$report" 2>/dev/null | sed 's/.*Risk Level: *//' | tr -d '\r' | awk '{print $1}')"
  case "$r" in
    SAFE|LOW|MEDIUM|HIGH|CRITICAL) printf '%s' "$r" ;;
    *) printf 'SCAN_FAILED' ;;
  esac
}

# Highest verdict accepted for a hand-reviewed skill, or "" if not reviewed.
REVIEWED_FILE="$KIT_DIR/config/reviewed-skills.tsv"
reviewed_max() {
  [ -f "$REVIEWED_FILE" ] || return 0
  awk -F'\t' -v n="$1" '!/^#/ && $1==n {print $2; exit}' "$REVIEWED_FILE"
}

# 0 = safe to install, 1 = do not install
gate_skill() {
  local dir="$1" sname="$2" report risk allowed ans
  [ "$SCAN_OK" = 1 ] || return 0
  report="$SCAN_DIR/$sname.txt"
  risk="$(risk_of "$dir" "$report")"

  [ "$risk" = "NOT_A_SKILL" ] && return 1

  if [ "$risk" = "SAFE" ] || [ "$risk" = "LOW" ]; then return 0; fi

  allowed="$(reviewed_max "$sname")"
  if [ -n "$allowed" ] && [ "$allowed" = "$risk" ]; then
    step "$sname — $risk, hand-reviewed (config/reviewed-skills.tsv)"
    return 0
  fi

  if [ "$risk" = "MEDIUM" ]; then
    warn "$sname — MEDIUM (usually a false positive; report: $report)"
    REVIEW+=("$sname [MEDIUM]"); return 0
  fi

  err "$sname — $risk"
  say "        report: $report"
  REVIEW+=("$sname [$risk]")
  if [ "$YES" = 1 ]; then
    warn "not installing $sname — $risk needs a human decision"
    return 1
  fi
  printf '        Install %s anyway? [y/N] ' "$sname"
  read -r ans </dev/tty || ans=""
  case "$ans" in [yY]*) return 0 ;; *) return 1 ;; esac
}

place_skill() {
  local src="$1" sname="$2" stamp
  if [ -e "$SKILLS_DIR/$sname" ]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR/$stamp"
    mv "$SKILLS_DIR/$sname" "$BACKUP_DIR/$stamp/$sname"
  fi
  cp -R "$src" "$SKILLS_DIR/$sname"
}

# Earlier versions of this installer left "<name>.bak" directories inside
# skills/, where Claude Code loads them as duplicate skills. Move any out.
migrate_stray_backups() {
  local n=0 stamp
  for b in "$SKILLS_DIR"/*.bak; do
    [ -d "$b" ] || continue
    [ "$n" = 0 ] && { stamp="migrated-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BACKUP_DIR/$stamp"; }
    mv "$b" "$BACKUP_DIR/$stamp/$(basename "$b" .bak)" 2>/dev/null && n=$((n+1))
  done
  [ "$n" -gt 0 ] && warn "moved $n stale *.bak skill(s) out of skills/ → $BACKUP_DIR/$stamp"
  return 0
}

install_skill_bundle() {
  # <fork-repo> <upstream|""> <subdir> <label>
  local primary="$1" fallback="$2" subdir="$3" label="$4"
  local name clone src n=0 skipped=0
  name="$(basename "$primary")"; clone="$WORK_DIR/$name"

  step "$label"
  if [ "$DRY" = 1 ]; then dry "clone $primary → scan each skill → $SKILLS_DIR"; return 0; fi

  if ! clone_repo "$primary" "$fallback" "$clone"; then
    err "clone failed: $primary${fallback:+ (and $fallback)}"
    FAILED+=("skills:$primary"); return 1
  fi
  [ "$CLONED_FROM" != "$primary" ] && warn "used upstream $CLONED_FROM (fork unavailable)"

  src="$clone/$subdir"
  if [ ! -d "$src" ]; then err "no skills dir '$subdir' in $CLONED_FROM"; FAILED+=("skills:$primary"); return 1; fi

  for s in "$src"/*/; do
    [ -d "$s" ] || continue
    local sname; sname="$(basename "$s")"
    if gate_skill "$s" "$sname"; then
      place_skill "$s" "$sname"; n=$((n+1))
    else
      skipped=$((skipped+1)); SKIPPED+=("skill:$sname (risk)")
    fi
  done

  ok "$label — $n installed$([ "$skipped" -gt 0 ] && echo ", $skipped blocked")"
  INSTALLED+=("skills:$label ($n)")
}

install_single_skill() {
  # <fork-repo> <upstream|""> <label> <skill-name>
  local primary="$1" fallback="$2" label="$3" sname="$4"
  local clone="$WORK_DIR/$sname"
  step "$label"
  if [ "$DRY" = 1 ]; then dry "clone $primary → scan → $SKILLS_DIR/$sname"; return 0; fi

  if ! clone_repo "$primary" "$fallback" "$clone"; then
    err "clone failed: $primary${fallback:+ (and $fallback)}"
    FAILED+=("skills:$primary"); return 1
  fi
  [ "$CLONED_FROM" != "$primary" ] && warn "used upstream $CLONED_FROM (fork unavailable)"
  [ -f "$clone/SKILL.md" ] || { err "no SKILL.md in $CLONED_FROM"; FAILED+=("skills:$primary"); return 1; }
  rm -rf "$clone/.git"

  if gate_skill "$clone" "$sname"; then
    place_skill "$clone" "$sname"
    ok "$label → $SKILLS_DIR/$sname"
    INSTALLED+=("skills:$label (1)")
  else
    SKIPPED+=("skill:$sname (risk)")
  fi
}

if [ "$DO_SKILLS" = 1 ]; then
  head_ "Security scanner"
  if [ "$DRY" = 1 ]; then
    dry "scanner bootstrap"
  elif npx --yes -p claude-skill-antivirus@latest claude-skill-av --version >/dev/null 2>&1; then
    SCAN_OK=1; ok "claude-skill-antivirus ready — every skill scanned before install"
    say  "      reports: $SCAN_DIR"
  else
    warn "scanner unavailable (offline or npm blocked) — installing UNSCANNED"
    warn "run ./scripts/scan-skills.sh once you're online"
  fi

  head_ "Skills"
  [ "$DRY" = 1 ] || migrate_stray_backups
  install_skill_bundle "abishekashwinakash3-dotcom/AIS-OS" "nateherkai/AIS-OS" \
    ".claude/skills" "AIS-OS (life/career OS)"
  install_skill_bundle "abishekashwinakash3-dotcom/hyperframes-student-kit" "nateherkai/hyperframes-student-kit" \
    ".claude/skills" "HyperFrames (video/reels)"
  install_single_skill "abishekashwinakash3-dotcom/SlopMonster" "ItsssssJack/SlopMonster" \
    "SlopMonster (de-AI your writing)" "slopmonster"
fi

# ============================================================
# MCP SERVERS
# ============================================================
have_key() { [ -n "${!1:-}" ]; }

add_mcp() {
  # add_mcp <name> <required-env-var|NONE> <claude mcp add args...>
  local name="$1"; shift
  local keyvar="$1"; shift
  if [ "$keyvar" != "NONE" ] && ! have_key "$keyvar"; then
    SKIPPED+=("mcp:$name (needs $keyvar)"); step "$name — skipped, no $keyvar"; return 0
  fi
  if [ "$DRY" = 1 ]; then dry "claude mcp add $name"; return 0; fi
  if claude mcp get "$name" >/dev/null 2>&1; then ok "$name (already configured)"; return 0; fi
  if claude mcp add "$name" --scope user "$@" >/dev/null 2>&1; then
    ok "$name"; INSTALLED+=("mcp:$name")
  else
    err "$name failed"; FAILED+=("mcp:$name")
  fi
}

if [ "$DO_MCP" = 1 ]; then
  head_ "MCP servers"
  if [ -f "$KIT_DIR/.env" ]; then
    set -a; . "$KIT_DIR/.env"; set +a
    ok "loaded keys from .env"
  else
    warn "no .env — keyless servers only (cp .env.example .env to add more)"
  fi

  add_mcp context7   NONE -- npx -y @upstash/context7-mcp
  add_mcp playwright NONE -- npx -y @playwright/mcp@latest
  add_mcp sequential-thinking NONE -- npx -y @modelcontextprotocol/server-sequential-thinking
  add_mcp memory     NONE -- npx -y @modelcontextprotocol/server-memory

  # Official fetch server (Python). The npm 'fetcher-mcp' package was tested
  # and fails to start (CONNECTION_CLOSED), so it is deliberately not used.
  if command -v uvx >/dev/null 2>&1; then
    add_mcp fetch NONE -- uvx mcp-server-fetch
  else
    SKIPPED+=("mcp:fetch (needs uv — https://docs.astral.sh/uv/)")
    step "fetch — skipped, uv not installed (playwright covers page fetching)"
  fi

  add_mcp exa        EXA_API_KEY       -e "EXA_API_KEY=${EXA_API_KEY:-}"           -- npx -y exa-mcp-server
  add_mcp tavily     TAVILY_API_KEY    -e "TAVILY_API_KEY=${TAVILY_API_KEY:-}"     -- npx -y tavily-mcp
  add_mcp firecrawl  FIRECRAWL_API_KEY -e "FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY:-}" -- npx -y firecrawl-mcp
  add_mcp supabase   SUPABASE_ACCESS_TOKEN -e "SUPABASE_ACCESS_TOKEN=${SUPABASE_ACCESS_TOKEN:-}" -- npx -y @supabase/mcp-server-supabase@latest

  # Searches the FindSkills directory (93,000+ agent skills). Pinned to 0.1.23,
  # NOT @latest: 0.1.24/0.1.25 ship api.js importing ./lib/auth-error.js, a file
  # the maintainer's own package.json "files" allowlist never includes in the
  # published tarball, so every install of those versions crashes with
  # ERR_MODULE_NOT_FOUND (confirmed by unpacking the npm tarball directly).
  # 0.1.23 has no such import and was smoke-tested to start and answer
  # tools/list cleanly. Revisit the pin once upstream fixes the publish.
  add_mcp findskills NONE -- npx -y findskills-mcp@0.1.23

  say ""
  step "GitHub MCP is an OAuth connector — run once, interactively:"
  say "      claude mcp add --transport http github https://api.githubcopilot.com/mcp"
  say "      claude mcp login github"
fi

# ============================================================
# SUMMARY
# ============================================================
head_ "Summary"
if [ ${#INSTALLED[@]} -gt 0 ]; then
  say "${G}Installed:${N}"; for i in "${INSTALLED[@]}"; do say "  ✓ $i"; done
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  say "${Y}Skipped:${N}";   for i in "${SKIPPED[@]}";   do say "  – $i"; done
fi
if [ ${#REVIEW[@]} -gt 0 ]; then
  say "${Y}Scan findings to read:${N}"
  for i in "${REVIEW[@]}"; do say "  ! $i"; done
  say "  reports: $SCAN_DIR   (docs/06 explains how to read them)"
fi
if [ ${#FAILED[@]} -gt 0 ]; then
  say "${R}Failed:${N}";    for i in "${FAILED[@]}";    do say "  ✗ $i"; done
fi

cat <<NEXT

${BOLD}Next:${N}
  1. Restart Claude Code so it picks up new skills/plugins.
  2. ./scripts/doctor.sh          — verify everything landed
  3. cp .env.example .env         — add free API keys (docs/05)
  4. ./scripts/sync-repos.sh      — pull your GitHub repos local (docs/01)
  5. docs/09-claude-chat-setup.md — the claude.ai chat half (manual)
NEXT

[ ${#FAILED[@]} -gt 0 ] && exit 1
exit 0
