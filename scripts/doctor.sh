#!/usr/bin/env bash
# What's installed, what's missing, what's broken.
set -uo pipefail
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[34m'; BOLD=$'\e[1m'; N=$'\e[0m'
else G=""; Y=""; R=""; B=""; BOLD=""; N=""; fi
h(){ printf '\n%s%s══ %s%s\n' "$BOLD" "$B" "$*" "$N"; }
ok(){ printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
no(){ printf '  %s✗%s %s\n' "$R" "$N" "$*"; }
mb(){ printf '  %s!%s %s\n' "$Y" "$N" "$*"; }

h "Tools"
for t in git claude node npm gh python3 docker; do
  if command -v "$t" >/dev/null 2>&1; then
    v="$("$t" --version 2>/dev/null | head -1)"; ok "$t — ${v:-present}"
  else
    case "$t" in
      git|claude|node) no "$t missing (required)" ;;
      gh)      mb "gh missing — needed for ./scripts/sync-repos.sh (docs/01)" ;;
      docker)  mb "docker missing — optional, only for pentest tools (docs/08)" ;;
      *)       mb "$t missing (optional)" ;;
    esac
  fi
done

h "GitHub auth"
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then ok "logged in as $(gh api user --jq .login 2>/dev/null || echo '?')"
  else no "not logged in — run: gh auth login"; fi
else mb "gh not installed"; fi

h "Skills ($CLAUDE_DIR/skills)"
if [ -d "$CLAUDE_DIR/skills" ]; then
  n=$(find "$CLAUDE_DIR/skills" -maxdepth 1 -mindepth 1 -type d ! -name '*.bak' | wc -l | tr -d ' ')
  ok "$n skills installed"
  find "$CLAUDE_DIR/skills" -maxdepth 1 -mindepth 1 -type d ! -name '*.bak' -exec basename {} \; | sort | paste -sd' ' - | fold -s -w 76 | sed 's/^/      /'
else no "no skills dir — run ./install.sh --skills"; fi

h "Plugins"
claude plugin list 2>/dev/null | sed 's/^/      /' || mb "could not list plugins"

h "MCP servers"
claude mcp list 2>/dev/null | sed 's/^/      /' || mb "could not list MCP servers"

h "API keys (.env)"
if [ -f "$KIT_DIR/.env" ]; then
  set -a; . "$KIT_DIR/.env" 2>/dev/null; set +a
  for k in GEMINI_API_KEY GROQ_API_KEY OPENROUTER_API_KEY MISTRAL_API_KEY CEREBRAS_API_KEY \
           NVIDIA_API_KEY COHERE_API_KEY EXA_API_KEY TAVILY_API_KEY FIRECRAWL_API_KEY; do
    if [ -n "${!k:-}" ]; then ok "$k set"; else mb "$k empty"; fi
  done
else
  mb "no .env — run: cp .env.example .env  (see docs/05-free-api-keys.md)"
fi

h "Secret safety"
if [ -f "$KIT_DIR/.env" ]; then
  if git -C "$KIT_DIR" check-ignore -q .env 2>/dev/null; then ok ".env is gitignored"
  else no ".env is NOT gitignored — add it before committing!"; fi
fi

printf '\n%sDone.%s\n' "$BOLD" "$N"
