#!/bin/bash
# Death-watch gateway: catat PID tiap 10 detik. Kalau PID berubah tanpa
# "Stopping" di journal (= mati mendadak/SIGKILL), simpan snapshot proses
# termuda untuk identifikasi pembunuh.
set -u
LOG="$HOME/.hermes/logs/gateway-deathwatch.log"
PIDFILE="$HOME/.cache/gateway-deathwatch-pid"
mkdir -p "$(dirname "$PIDFILE")"

cur_pid() { systemctl --user show hermes-gateway.service -p MainPID --value 2>/dev/null; }

LAST="0"
[ -f "$PIDFILE" ] && LAST=$(cat "$PIDFILE" 2>/dev/null || echo 0)
CUR=$(cur_pid)
echo "$CUR" > "$PIDFILE"

if [ "$LAST" != "0" ] && [ "$CUR" != "0" ] && [ "$LAST" != "$CUR" ]; then
  STOPPING=$(journalctl --user -u hermes-gateway.service --no-pager --since "2 minutes ago" 2>&1 | grep -ac "Stopping gateway")
  echo "=== $(date '+%F %T') PID berubah $LAST -> $CUR (stopping_lines=$STOPPING) ===" >> "$LOG"
  ps -eo pid,lstart,cmd --sort=-lstart 2>/dev/null | head -n 15 >> "$LOG"
  journalctl --user -u hermes-gateway.service --no-pager --since "2 minutes ago" 2>&1 | grep -aE "Main process exited|Started" | tail -n 4 >> "$LOG"
fi
