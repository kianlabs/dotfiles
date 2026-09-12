#!/bin/bash
# 9router watchdog - tidak agresif: timeout 15s, grace 90s setelah start, restart hanya setelah 2x gagal beruntun.
set -u
PORT=20128
TIMEOUT=15
GRACE_SEC=90
FAILFILE="$HOME/.cache/9router-watchdog-failcount"

# 1. Grace period: jangan cek saat service baru (cold-start next-server bisa 15-30s)
if systemctl --user is-active --quiet 9router.service; then
  MONO_US=$(systemctl --user show 9router.service -p ActiveEnterTimestampMonotonic --value 2>/dev/null || echo 0)
  UPTIME_S=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
  if [ "$MONO_US" != "0" ] && [ "$UPTIME_S" != "0" ]; then
    ELAPSED=$(( UPTIME_S - MONO_US / 1000000 ))
    if [ "$ELAPSED" -lt "$GRACE_SEC" ]; then
      echo "watchdog: skip check, 9router baru jalan ${ELAPSED}s (< ${GRACE_SEC}s grace)"
      exit 0
    fi
  fi
else
  echo "watchdog: 9router tidak active, coba start"
  systemctl --user start 9router.service
  exit 0
fi

# 2. Health check: probe "/" (statis, 0.003s) — JANGAN pakai /v1/models
# karena handler-nya ikut macet saat upstream kiro hang, padahal chat tetap jalan.
if curl -sS -m "$TIMEOUT" -o /dev/null "http://127.0.0.1:${PORT}/"; then
  echo 0 > "$FAILFILE"
  exit 0
fi

# 3. Gagal -> hitung beruntun
COUNT=0
[ -f "$FAILFILE" ] && COUNT=$(cat "$FAILFILE" 2>/dev/null || echo 0)
case "$COUNT" in ''|*[!0-9]*) COUNT=0;; esac
COUNT=$((COUNT + 1))
echo "$COUNT" > "$FAILFILE"

if [ "$COUNT" -ge 2 ]; then
  echo "watchdog: 9router port dead 2x beruntun (timeout ${TIMEOUT}s), restarting"
  echo 0 > "$FAILFILE"
  systemctl --user restart 9router.service
else
  echo "watchdog: percobaan $COUNT/2 gagal, belum restart (tunggu cek berikutnya)"
fi
