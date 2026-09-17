#!/usr/bin/env bash
# EVERYTHING-NEED — Claude Code setup installer
# Usage: ./install.sh --all | --plugins | --skills | --mcp [--dry-run] [--yes]
set -uo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
WORK_DIR="${TMPDIR:-/tmp}/ainstall-$$"

DO_PLUGINS=0; DO_SKILLS=0; DO_MCP=0; DRY=0; YES=0
FAILED=(); INSTALLED=(); SKIPPED=()

# ---------- output ----------
if [ -t 1 ]; then R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[34m'; BOLD=$'\e[1m'; N=$'\e[0m'
else R=""; G=""; Y=""; B=""; BOLD=""; N=""; fi
say()  { printf '%s\n' "$*"; }
head_(){ printf '\n%s%s══ %s%s\n' "$BOLD" "$B" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
err()  { printf '  %s✗%s %s\n' "$R" "$N" "$*"; }
step() { printf '  %s·%s %s\n' "$B" "$N" "$*"; }
run()  { if [ "$DRY" = 1 ]; then printf '  %s[dry]%s %s\n' "$Y" "$N" "$*"; return 0; fi; "$@"; }

usage() {
  cat <<USAGE
EVERYTHING-NEED installer

  ./install.sh --all         Install plugins + skills + MCP servers
  ./install.sh --plugins     Claude Code plugin marketplaces only
  ./install.sh --skills      Skill bundles only (security-scanned first)
  ./install.sh --mcp         MCP servers only

  --dry-run   Show what would happen, change nothing
  --yes       Don't prompt for confirmation
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
need git   "install from https://git-scm.com"
need claude "install: npm i -g @anthropic-ai/claude-code"
if [ "$DO_MCP" = 1 ] || [ "$DO_SKILLS" = 1 ]; then
  need node "install Node 18+ from https://nodejs.org"
fi
if [ "$DO_PLUGINS" = 1 ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    ok "gh authenticated — private/own-fork marketplaces will clone"
  else
    warn "gh not authenticated — marketplaces from YOUR OWN repos will fail to clone"
    say  "      run 'gh auth login' first if you want those (docs/01)"
  fi
fi
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${NODE_MAJOR:-0}" -lt 18 ]; then err "Node $NODE_MAJOR is too old — need 18+"; MISSING=1; fi
fi
[ "$MISSING" = 1 ] && { err "Fix the above, then re-run."; exit 1; }

if [ "$YES" != 1 ] && [ "$DRY" != 1 ]; then
  say ""
  say "This installs into: ${BOLD}$CLAUDE_DIR${N}"
  printf 'Continue? [y/N] '
  read -r reply </dev/tty || reply=""
  case "$reply" in [yY]*) ;; *) say "Aborted."; exit 0 ;; esac
fi

mkdir -p "$WORK_DIR" "$SKILLS_DIR"

# ============================================================
# PLUGINS
# ============================================================
auth_hint_shown=0
gh_auth_hint() {
  [ "$auth_hint_shown" = 1 ] && return 0
  auth_hint_shown=1
  warn "GitHub auth is needed to clone this source. Fix with:"
  say  "        gh auth login          # then re-run: ./install.sh --plugins"
  say  "      (see docs/01-github-local-sync.md)"
}

add_marketplace() {
  local repo="$1" label="$2" out rc
  step "marketplace: $label"
  if [ "$DRY" = 1 ]; then printf '  %s[dry]%s claude plugin marketplace add %s\n' "$Y" "$N" "$repo"; return 0; fi

  out="$(claude plugin marketplace add "$repo" 2>&1)"; rc=$?
  # "already added" counts as success
  if claude plugin marketplace list 2>/dev/null | grep -qi "$(basename "$repo")"; then
    ok "$repo"; return 0
  fi

  err "could not add $repo"
  # Show the real reason instead of swallowing it
  printf '%s\n' "$out" | grep -viE '^\s*$' | head -3 | sed 's/^/        /'
  case "$out" in
    *"authentication failed"*|*"could not read Username"*|*"Authentication failed"*|*"terminal prompts disabled"*)
      gh_auth_hint ;;
  esac
  FAILED+=("marketplace:$repo"); return 1
}

install_plugin() {
  local plugin="$1" label="$2" out
  step "plugin: $label"
  if [ "$DRY" = 1 ]; then printf '  %s[dry]%s claude plugin install %s\n' "$Y" "$N" "$plugin"; return 0; fi

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
  # ECC — 68 agents / 292 skills / 94 commands
  add_marketplace "affaan-m/ECC" "ECC (agents + skills + hooks)" \
    && install_plugin "ecc@ecc" "ECC operator layer"
  # scroll-craft — front-end / scroll-driven design
  add_marketplace "abishekashwinakash3-dotcom/scroll-craft" "nateherk design" \
    && install_plugin "nateherk-design@nateherk" "scroll-craft landing pages"
fi

# ============================================================
# SKILLS
# ============================================================
SCAN_OK=0
security_scan() {
  # Scan a directory of skills BEFORE copying into ~/.claude/skills
  local target="$1"
  if [ "$SCAN_OK" != 1 ]; then return 2; fi
  npx --yes -p claude-skill-antivirus@latest claude-skill-av --scan-only -v "$target" 2>&1
}

install_skill_bundle() {
  local repo="$1" subdir="$2" label="$3"
  local name; name="$(basename "$repo")"
  local clone="$WORK_DIR/$name"

  step "$label — cloning"
  if ! run git clone --depth 1 --quiet "https://github.com/$repo" "$clone"; then
    err "clone failed: $repo"; FAILED+=("skills:$repo"); return 1
  fi
  [ "$DRY" = 1 ] && { ok "$label (dry-run)"; return 0; }

  local src="$clone/$subdir"
  if [ ! -d "$src" ]; then err "no skills dir at $subdir in $repo"; FAILED+=("skills:$repo"); return 1; fi

  # Security gate
  if [ "$SCAN_OK" = 1 ]; then
    if security_scan "$src" >"$WORK_DIR/$name.scan" 2>&1; then
      ok "scan clean"
    else
      warn "scanner flagged $label — report: $WORK_DIR/$name.scan"
      if [ "$YES" != 1 ]; then
        printf '    Install anyway? [y/N] '
        read -r r </dev/tty || r=""
        case "$r" in [yY]*) ;; *) SKIPPED+=("skills:$repo (flagged)"); return 0 ;; esac
      fi
    fi
  fi

  local n=0
  for s in "$src"/*/; do
    [ -d "$s" ] || continue
    local sname; sname="$(basename "$s")"
    if [ -e "$SKILLS_DIR/$sname" ]; then
      rm -rf "$SKILLS_DIR/$sname.bak" 2>/dev/null
      mv "$SKILLS_DIR/$sname" "$SKILLS_DIR/$sname.bak"
    fi
    cp -R "$s" "$SKILLS_DIR/$sname" && n=$((n+1))
  done
  ok "$label — $n skills → $SKILLS_DIR"
  INSTALLED+=("skills:$label ($n)")
}

install_single_skill() {
  # Repo whose ROOT is one skill (has SKILL.md at top level)
  local repo="$1" label="$2" sname="$3"
  local clone="$WORK_DIR/$sname"
  step "$label — cloning"
  if ! run git clone --depth 1 --quiet "https://github.com/$repo" "$clone"; then
    err "clone failed: $repo"; FAILED+=("skills:$repo"); return 1
  fi
  [ "$DRY" = 1 ] && { ok "$label (dry-run)"; return 0; }
  if [ ! -f "$clone/SKILL.md" ]; then err "no SKILL.md in $repo"; FAILED+=("skills:$repo"); return 1; fi
  rm -rf "$clone/.git"
  [ -e "$SKILLS_DIR/$sname" ] && { rm -rf "$SKILLS_DIR/$sname.bak"; mv "$SKILLS_DIR/$sname" "$SKILLS_DIR/$sname.bak"; }
  cp -R "$clone" "$SKILLS_DIR/$sname"
  ok "$label → $SKILLS_DIR/$sname"
  INSTALLED+=("skills:$label (1)")
}

if [ "$DO_SKILLS" = 1 ]; then
  head_ "Security scanner"
  if [ "$DRY" = 1 ]; then
    warn "dry-run: skipping scanner bootstrap"
  elif npx --yes -p claude-skill-antivirus@latest claude-skill-av --version >/dev/null 2>&1; then
    SCAN_OK=1; ok "claude-skill-antivirus ready — skills scanned before install"
  else
    warn "scanner unavailable (offline or npm blocked) — installing UNSCANNED"
    warn "run ./scripts/scan-skills.sh later"
  fi

  head_ "Skills"
  install_skill_bundle "abishekashwinakash3-dotcom/AIS-OS" ".claude/skills" "AIS-OS (life/career OS)"
  install_skill_bundle "abishekashwinakash3-dotcom/hyperframes-student-kit" ".claude/skills" "HyperFrames (video/reels)"
  install_single_skill "abishekashwinakash3-dotcom/SlopMonster" "SlopMonster (de-AI your writing)" "slopmonster"
fi

# ============================================================
# MCP SERVERS
# ============================================================
have_key() { [ -n "${!1:-}" ]; }

add_mcp() {
  # add_mcp <name> <required-env-var-or-NONE> <command...>
  local name="$1"; shift
  local keyvar="$1"; shift
  if [ "$keyvar" != "NONE" ] && ! have_key "$keyvar"; then
    SKIPPED+=("mcp:$name (needs $keyvar)"); step "$name — skipped, no $keyvar"; return 0
  fi
  if claude mcp get "$name" >/dev/null 2>&1; then ok "$name (already configured)"; return 0; fi
  if run claude mcp add "$name" --scope user "$@" >/dev/null 2>&1; then
    ok "$name"; INSTALLED+=("mcp:$name")
  else
    err "$name failed"; FAILED+=("mcp:$name")
  fi
}

if [ "$DO_MCP" = 1 ]; then
  head_ "MCP servers"
  # Load keys if present
  if [ -f "$KIT_DIR/.env" ]; then
    set -a; . "$KIT_DIR/.env"; set +a
    ok "loaded keys from .env"
  else
    warn "no .env — keyless servers only (cp .env.example .env to add more)"
  fi

  # --- keyless ---
  add_mcp context7   NONE -- npx -y @upstash/context7-mcp
  add_mcp playwright NONE -- npx -y @playwright/mcp@latest
  # Official MCP fetch server (Python). Needs `uv` — the npm `fetcher-mcp`
  # package was tested and fails to start (CONNECTION_CLOSED), so it is not used.
  if command -v uvx >/dev/null 2>&1; then
    add_mcp fetch NONE -- uvx mcp-server-fetch
  else
    SKIPPED+=("mcp:fetch (needs uv — https://docs.astral.sh/uv/)")
    step "fetch — skipped, uv not installed (playwright covers page fetching)"
  fi
  add_mcp sequential-thinking NONE -- npx -y @modelcontextprotocol/server-sequential-thinking
  add_mcp memory     NONE -- npx -y @modelcontextprotocol/server-memory

  # --- keyed ---
  add_mcp exa        EXA_API_KEY       -e "EXA_API_KEY=${EXA_API_KEY:-}"           -- npx -y exa-mcp-server
  add_mcp tavily     TAVILY_API_KEY    -e "TAVILY_API_KEY=${TAVILY_API_KEY:-}"     -- npx -y tavily-mcp
  add_mcp firecrawl  FIRECRAWL_API_KEY -e "FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY:-}" -- npx -y firecrawl-mcp
  add_mcp supabase   SUPABASE_ACCESS_TOKEN -e "SUPABASE_ACCESS_TOKEN=${SUPABASE_ACCESS_TOKEN:-}" -- npx -y @supabase/mcp-server-supabase@latest

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
  say "${Y}Skipped:${N}"; for i in "${SKIPPED[@]}"; do say "  – $i"; done
fi
if [ ${#FAILED[@]} -gt 0 ]; then
  say "${R}Failed:${N}"; for i in "${FAILED[@]}"; do say "  ✗ $i"; done
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
