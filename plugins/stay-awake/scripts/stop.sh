#!/bin/bash
# stay-awake: stop this Claude process's caffeinate.
#
# Called when Claude yields control back to you (Stop, SessionEnd) or pauses to
# wait for input (AskUserQuestion / ExitPlanMode / permission / idle prompt).
# Idempotent — a missing or already-dead caffeinate is a harmless no-op.
set -uo pipefail

[ "$(uname -s)" = "Darwin" ] || exit 0

CLAUDE_PID="$PPID"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/stay-awake/sessions"
PID_FILE="$CACHE_DIR/$CLAUDE_PID.pid"
[ -f "$PID_FILE" ] || exit 0

CAFF_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -n "$CAFF_PID" ] && kill -0 "$CAFF_PID" 2>/dev/null; then
  kill "$CAFF_PID" 2>/dev/null || true
fi
rm -f "$PID_FILE"
exit 0
