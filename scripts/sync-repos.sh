#!/usr/bin/env bash
# Clone every GitHub repo you own into ~/code, or pull if already there.
# Usage: ./scripts/sync-repos.sh [target-dir] [--dry-run]
set -uo pipefail

TARGET="${1:-$HOME/code}"
[ "${1:-}" = "--dry-run" ] && { TARGET="$HOME/code"; DRY=1; } || DRY=0
[ "${2:-}" = "--dry-run" ] && DRY=1

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[34m'; BOLD=$'\e[1m'; N=$'\e[0m'
else G=""; Y=""; R=""; B=""; BOLD=""; N=""; fi

command -v gh >/dev/null 2>&1 || {
  printf '%s✗%s GitHub CLI not installed.\n' "$R" "$N"
  echo "  macOS:   brew install gh"
  echo "  Windows: winget install --id GitHub.cli -e"
  echo "  Linux:   sudo apt install gh"
  exit 1; }

gh auth status >/dev/null 2>&1 || {
  printf '%s✗%s Not logged in. Run: %sgh auth login%s\n' "$R" "$N" "$BOLD" "$N"; exit 1; }

USER_LOGIN="$(gh api user --jq .login 2>/dev/null)" || { echo "Could not read GitHub user"; exit 1; }
printf '%s══ Syncing repos for %s → %s%s\n\n' "$BOLD" "$USER_LOGIN" "$TARGET" "$N"

mkdir -p "$TARGET"
CLONED=0; PULLED=0; DIRTY=0; FAILED=0

# --limit 1000 covers any realistic account
gh repo list "$USER_LOGIN" --limit 1000 --json nameWithOwner,name --jq '.[] | [.nameWithOwner, .name] | @tsv' \
| while IFS=$'\t' read -r full name; do
  dest="$TARGET/$name"
  if [ -d "$dest/.git" ]; then
    if [ -n "$(git -C "$dest" status --porcelain 2>/dev/null)" ]; then
      printf '  %s!%s %-38s uncommitted changes — skipping pull\n' "$Y" "$N" "$name"
      continue
    fi
    if [ "$DRY" = 1 ]; then printf '  %s[dry]%s pull %s\n' "$Y" "$N" "$name"; continue; fi
    if git -C "$dest" pull --quiet --ff-only 2>/dev/null; then
      printf '  %s↓%s %-38s updated\n' "$B" "$N" "$name"
    else
      printf '  %s!%s %-38s pull needs attention (diverged?)\n' "$Y" "$N" "$name"
    fi
  else
    if [ "$DRY" = 1 ]; then printf '  %s[dry]%s clone %s\n' "$Y" "$N" "$full"; continue; fi
    if gh repo clone "$full" "$dest" -- --quiet 2>/dev/null; then
      printf '  %s✓%s %-38s cloned\n' "$G" "$N" "$name"
    else
      printf '  %s✗%s %-38s clone failed\n' "$R" "$N" "$name"
    fi
  fi
done

printf '\n%sDone.%s Your repos live in %s\n' "$BOLD" "$N" "$TARGET"
echo "Open one with Claude Code:   cd $TARGET/<repo> && claude"
