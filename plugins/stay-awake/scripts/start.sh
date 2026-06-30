#!/bin/bash
# stay-awake: start (or resume) caffeinate while Claude Code is working.
#
# Idempotent — safe to call on every UserPromptSubmit / PostToolUse.
# Keyed by Claude's process id (PPID), so it survives session_id rotation
# (/compact, /clear, /resume, auto-compact) within the same process.
set -uo pipefail

# macOS only — silently no-op on other platforms.
[ "$(uname -s)" = "Darwin" ] || exit 0
command -v caffeinate >/dev/null 2>&1 || exit 0

CLAUDE_PID="$PPID"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/stay-awake/sessions"
mkdir -p "$CACHE_DIR"
PID_FILE="$CACHE_DIR/$CLAUDE_PID.pid"

# Already running for this process? Nothing to do (idempotent).
if [ -f "$PID_FILE" ]; then
  EXISTING="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$EXISTING" ] && kill -0 "$EXISTING" 2>/dev/null; then
    exit 0
  fi
  rm -f "$PID_FILE"
fi

# -i : prevent idle *system* sleep (the display may still sleep — that's fine,
#      Claude keeps working). Closing the laptop lid still sleeps the machine.
# -w : tie caffeinate's lifetime to the Claude process. When Claude exits for
#      any reason (quit, Ctrl+C, crash, /clear), caffeinate dies with it, so it
#      can never be left orphaned holding the machine awake.
nohup caffeinate -i -w "$CLAUDE_PID" </dev/null >/dev/null 2>&1 &
echo "$!" > "$PID_FILE"
disown 2>/dev/null || true
exit 0
