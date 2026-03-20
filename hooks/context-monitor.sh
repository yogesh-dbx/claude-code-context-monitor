#!/usr/bin/env bash
# PostToolUse hook — warns when context window usage gets high
# Install: copy to ~/.claude/hooks/context-monitor.sh && chmod +x
set -euo pipefail

# Clean up stale bridge/sentinel files from old sessions (older than 1 day)
find "$HOME/.claude" -name ".context-pct-*" -mtime +1 -delete 2>/dev/null || true
find "$HOME/.claude" -name ".context-warned-*" -mtime +1 -delete 2>/dev/null || true

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
BRIDGE_FILE="$HOME/.claude/.context-pct-$SESSION_ID"

# No bridge file yet (statusline hasn't run) — skip silently
[ ! -f "$BRIDGE_FILE" ] && exit 0

PCT=$(cat "$BRIDGE_FILE" 2>/dev/null || echo 0)

# 60% — warn once per session
if [ "$PCT" -ge 60 ] && [ "$PCT" -lt 80 ]; then
  WARN_FILE="$HOME/.claude/.context-warned-60-$SESSION_ID"
  if [ ! -f "$WARN_FILE" ]; then
    touch "$WARN_FILE"
    echo "⚠️  Context at ${PCT}%. Be concise — avoid verbose outputs and unnecessary file reads."
  fi
fi

# 80% — warn once per session
if [ "$PCT" -ge 80 ]; then
  WARN_FILE="$HOME/.claude/.context-warned-80-$SESSION_ID"
  if [ ! -f "$WARN_FILE" ]; then
    touch "$WARN_FILE"
    echo "🔴 Context at ${PCT}%. Consider saving state before auto-compaction kicks in."
  fi
fi

exit 0
