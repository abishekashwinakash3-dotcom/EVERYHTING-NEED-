#!/usr/bin/env bash
# Security-scan every installed Claude skill.
# Usage: ./scripts/scan-skills.sh [skills-dir]
set -uo pipefail

SKILLS_DIR="${1:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}"
if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; BOLD=$'\e[1m'; N=$'\e[0m'
else G=""; Y=""; R=""; BOLD=""; N=""; fi

[ -d "$SKILLS_DIR" ] || { printf '%s✗%s No skills dir: %s\n' "$R" "$N" "$SKILLS_DIR"; exit 1; }

printf '%s══ Scanning skills in %s%s\n\n' "$BOLD" "$SKILLS_DIR" "$N"
command -v npx >/dev/null 2>&1 || { printf '%s✗%s npx required (install Node 18+)\n' "$R" "$N"; exit 1; }

REPORT_DIR="${TMPDIR:-/tmp}/skill-scans"
mkdir -p "$REPORT_DIR"
CLEAN=0; FLAGGED=0

for d in "$SKILLS_DIR"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  case "$name" in *.bak) continue ;; esac
  out="$REPORT_DIR/$name.txt"
  if npx --yes -p claude-skill-antivirus@latest claude-skill-av --scan-only -v "$d" >"$out" 2>&1; then
    risk="$(grep -m1 'Risk Level:' "$out" | sed 's/.*Risk Level: *//' | tr -d '\r')"
    case "$risk" in
      SAFE|LOW) printf '  %s✓%s %-30s %s\n' "$G" "$N" "$name" "${risk:-SAFE}"; CLEAN=$((CLEAN+1)) ;;
      *)        printf '  %s!%s %-30s %s  → %s\n' "$Y" "$N" "$name" "${risk:-?}" "$out"; FLAGGED=$((FLAGGED+1)) ;;
    esac
  else
    printf '  %s✗%s %-30s scan error → %s\n' "$R" "$N" "$name" "$out"; FLAGGED=$((FLAGGED+1))
  fi
done

printf '\n%sClean: %d   Needs review: %d%s\n' "$BOLD" "$CLEAN" "$FLAGGED" "$N"
echo "Full reports: $REPORT_DIR"
[ "$FLAGGED" -gt 0 ] && {
  echo ""
  echo "A flag is NOT proof of malice — the scanner pattern-matches and is noisy."
  echo "Matches inside dist/, build/ or *.min.js are usually false positives."
  echo "Open the report, trace the finding to a real line, then decide."
  echo "See docs/06-security.md -> 'Reading the results'."
  echo ""
  echo "Remove a skill with:  rm -rf \"$SKILLS_DIR/<name>\""
}
exit 0
