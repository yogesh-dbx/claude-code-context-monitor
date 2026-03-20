#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Installing Claude Code Context Monitor..."

# Check jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Determine script source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directories
mkdir -p "$HOOKS_DIR"

# Copy scripts
cp "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
cp "$SCRIPT_DIR/hooks/context-monitor.sh" "$HOOKS_DIR/context-monitor.sh"
chmod +x "$CLAUDE_DIR/statusline.sh" "$HOOKS_DIR/context-monitor.sh"

echo "  ✓ statusline.sh → ~/.claude/statusline.sh"
echo "  ✓ context-monitor.sh → ~/.claude/hooks/context-monitor.sh"

# Merge settings
if [ -f "$SETTINGS" ]; then
  BACKUP="$SETTINGS.backup.$(date +%s)"
  cp "$SETTINGS" "$BACKUP"
  echo "  ✓ Backed up existing settings → $(basename "$BACKUP")"

  # Merge using jq
  EXAMPLE="$SCRIPT_DIR/settings.example.json"
  MERGED=$(jq -s '
    .[0] as $existing |
    .[1] as $new |
    $existing
    | .statusLine = $new.statusLine
    | .hooks.PostToolUse = (
        ($existing.hooks.PostToolUse // [])
        | if any(.[].hooks[]; .command == "~/.claude/hooks/context-monitor.sh")
          then .
          else . + $new.hooks.PostToolUse
          end
      )
    | .env = ($existing.env // {}) + $new.env
  ' "$SETTINGS" "$EXAMPLE")

  echo "$MERGED" | jq '.' > "$SETTINGS"
  echo "  ✓ Merged settings into ~/.claude/settings.json"
else
  cp "$SCRIPT_DIR/settings.example.json" "$SETTINGS"
  echo "  ✓ Created ~/.claude/settings.json"
fi

echo ""
echo "Done! Restart Claude Code to see the status line."
echo ""
echo "  Status line: model | branch | ctx% | cost | +added/-removed"
echo "  Warnings:    ⚠️ at 60%  |  🔴 at 80%"
