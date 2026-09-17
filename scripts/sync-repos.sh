#!/usr/bin/env bash
# Clone every GitHub repo you own into a local folder, or pull if already there.
# Usage: ./scripts/sync-repos.sh [target-dir] [--dry-run]
set -uo pipefail

TARGET="$HOME/code"; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --help|-h) echo "Usage: $0 [target-dir] [--dry-run]"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  TARGET="$1" ;;
  esac; shift
done

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

CLONED=0; PULLED=0; DIRTY=0; PROBLEM=0

# Process substitution (not a pipe) so the counters survive the loop.
while IFS=$'\t' read -r full name; do
  [ -n "$name" ] || continue
  dest="$TARGET/$name"
  if [ -d "$dest/.git" ]; then
    if [ -n "$(git -C "$dest" status --porcelain 2>/dev/null)" ]; then
      printf '  %s!%s %-38s uncommitted changes — not pulling\n' "$Y" "$N" "$name"
      DIRTY=$((DIRTY+1)); continue
    fi
    if [ "$DRY" = 1 ]; then printf '  %s[dry]%s pull %s\n' "$Y" "$N" "$name"; continue; fi
    if git -C "$dest" pull --quiet --ff-only 2>/dev/null; then
      printf '  %s↓%s %-38s updated\n' "$B" "$N" "$name"; PULLED=$((PULLED+1))
    else
      printf '  %s!%s %-38s pull failed (diverged? check manually)\n' "$Y" "$N" "$name"
      PROBLEM=$((PROBLEM+1))
    fi
  else
    if [ "$DRY" = 1 ]; then printf '  %s[dry]%s clone %s\n' "$Y" "$N" "$full"; continue; fi
    if gh repo clone "$full" "$dest" -- --quiet 2>/dev/null; then
      printf '  %s✓%s %-38s cloned\n' "$G" "$N" "$name"; CLONED=$((CLONED+1))
    else
      printf '  %s✗%s %-38s clone failed\n' "$R" "$N" "$name"; PROBLEM=$((PROBLEM+1))
    fi
  fi
done < <(gh repo list "$USER_LOGIN" --limit 1000 --json nameWithOwner,name \
           --jq '.[] | [.nameWithOwner, .name] | @tsv')

printf '\n%sCloned %d · Updated %d · Skipped (uncommitted) %d · Problems %d%s\n' \
  "$BOLD" "$CLONED" "$PULLED" "$DIRTY" "$PROBLEM" "$N"
[ "$DIRTY" -gt 0 ] && echo "Repos with uncommitted work were left alone. Commit or stash, then re-run."
echo ""
echo "Open one with Claude Code:   cd $TARGET/<repo> && claude"
