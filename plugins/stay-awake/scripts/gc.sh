#!/bin/bash
# stay-awake: on SessionStart, garbage-collect pid files left behind by Claude
# processes that have since died (e.g. a crash where the Stop hook never ran).
# The `-w` backstop in start.sh already kills those caffeinates when the Claude
# process exits; this just clears the stale pid files (and kills any leftover
# caffeinate just in case).
set -uo pipefail

[ "$(uname -s)" = "Darwin" ] || exit 0

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/stay-awake/sessions"
[ -d "$CACHE_DIR" ] || exit 0

for f in "$CACHE_DIR"/*.pid; do
  [ -e "$f" ] || continue
  CLAUDE_PID="$(basename "$f" .pid)"

  # Claude process still alive → its caffeinate is still valid, leave it.
  if [ -n "$CLAUDE_PID" ] && kill -0 "$CLAUDE_PID" 2>/dev/null; then
    continue
  fi

  CAFF_PID="$(cat "$f" 2>/dev/null || true)"
  if [ -n "$CAFF_PID" ] && kill -0 "$CAFF_PID" 2>/dev/null; then
    kill "$CAFF_PID" 2>/dev/null || true
  fi
  rm -f "$f"
done
exit 0
