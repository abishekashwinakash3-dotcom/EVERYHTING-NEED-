#!/usr/bin/env bash
# Security-scan every installed Claude skill.
# Usage: ./scripts/scan-skills.sh [skills-dir]
set -uo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="${1:-$CLAUDE_DIR/skills}"
REPORT_DIR="$CLAUDE_DIR/skill-scans"     # same place install.sh writes

if [ -t 1 ]; then G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; BOLD=$'\e[1m'; N=$'\e[0m'
else G=""; Y=""; R=""; BOLD=""; N=""; fi

[ -d "$SKILLS_DIR" ] || { printf '%s✗%s No skills dir: %s\n' "$R" "$N" "$SKILLS_DIR"; exit 1; }
command -v npx >/dev/null 2>&1 || { printf '%s✗%s npx required (install Node 18+)\n' "$R" "$N"; exit 1; }

printf '%s══ Scanning skills in %s%s\n\n' "$BOLD" "$SKILLS_DIR" "$N"
mkdir -p "$REPORT_DIR"
CLEAN=0; MEDIUM=0; HIGH=0; FAILEDSCAN=0; NOTSKILL=0

for d in "$SKILLS_DIR"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  case "$name" in *.bak) continue ;; esac

  # Not every directory under skills/ is a skill (harness/session artifacts
  # live here too). Those are not a security finding — don't report them as one.
  if [ ! -f "$d/SKILL.md" ]; then
    printf '  %s·%s %-30s %s\n' "$Y" "$N" "$name" "not a skill (no SKILL.md), skipped"
    NOTSKILL=$((NOTSKILL+1)); continue
  fi

  out="$REPORT_DIR/$name.txt"
  # The scanner exits 0 regardless of risk — parse the report, not $?.
  npx --yes -p claude-skill-antivirus@latest claude-skill-av --scan-only -v "$d" >"$out" 2>&1 || true
  risk="$(grep -m1 'Risk Level:' "$out" 2>/dev/null | sed 's/.*Risk Level: *//' | tr -d '\r' | awk '{print $1}')"

  case "${risk:-}" in
    SAFE|LOW) printf '  %s✓%s %-30s %s\n'      "$G" "$N" "$name" "$risk";  CLEAN=$((CLEAN+1)) ;;
    MEDIUM)   printf '  %s!%s %-30s %-11s %s\n' "$Y" "$N" "$name" "$risk" "$out"; MEDIUM=$((MEDIUM+1)) ;;
    HIGH|CRITICAL)
              printf '  %s✗%s %-30s %-11s %s\n' "$R" "$N" "$name" "$risk" "$out"; HIGH=$((HIGH+1)) ;;
    *)        printf '  %s✗%s %-30s %-11s %s\n' "$R" "$N" "$name" "SCAN_FAILED" "$out"
              FAILEDSCAN=$((FAILEDSCAN+1)) ;;
  esac
done

printf '\n%sClean %d · Medium %d · High/Critical %d · Scan failed %d · Not skills %d%s\n' \
  "$BOLD" "$CLEAN" "$MEDIUM" "$HIGH" "$FAILEDSCAN" "$NOTSKILL" "$N"
echo "Reports: $REPORT_DIR"
if [ "$FAILEDSCAN" -gt 0 ]; then
  cat <<'TIP'

SCAN_FAILED means the scanner crashed and produced NO verdict — that is not
the same as "clean". A skill can crash the parser on purpose to avoid being
scanned, so treat these as unverified and read them yourself.
TIP
fi
if [ "$MEDIUM" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
  cat <<'TIP'

A flag is NOT proof of malice — this scanner pattern-matches and is noisy.
Matches inside dist/, build/ or *.min.js are usually false positives.
Open the report, trace the finding to a real line, then decide.
See docs/06-security.md -> "Reading the results".

Remove a skill with:  rm -rf ~/.claude/skills/<name>
TIP
fi
exit 0
