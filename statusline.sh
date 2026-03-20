#!/usr/bin/env bash
# Claude Code status line — context %, model, git branch, cost, lines changed
# Install: copy to ~/.claude/statusline.sh && chmod +x
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
SESSION_ID=$(echo "$input" | jq -r '.session_id // "unknown"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Bridge: write context % so the PostToolUse hook can read it
echo "$PCT" > "$HOME/.claude/.context-pct-$SESSION_ID" 2>/dev/null

# Git branch
BRANCH=""
if cd "$DIR" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
fi

# Color code: green < 50%, yellow 50-75%, red > 75%
if [ "$PCT" -lt 50 ]; then
  C="\033[32m"
elif [ "$PCT" -lt 75 ]; then
  C="\033[33m"
else
  C="\033[31m"
fi
R="\033[0m"

COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${MODEL} | ${BRANCH:-detached} | ${C}${PCT}%${R} ctx | ${COST_FMT} | +${ADDED}/-${REMOVED}"
