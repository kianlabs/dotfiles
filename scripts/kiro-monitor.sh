#!/bin/bash
# Probe kesehatan kiro via 9router tiap 10 menit. Log untuk bukti laporan hang.
# OK   = respons 200 berisi konten. HANG/FAIL = timeout / empty reply / non-200.
set -u
LOG="$HOME/.9router/logs/kiro-monitor.log"
TIMEOUT=40

# Ambil API key 9router dari .env hermes (tanpa mencetaknya ke log)
KEY=""
if [ -f "$HOME/.hermes/.env" ]; then
  KEY=$(grep -E '^HERMES_CUSTOM_LOCALHOST_20128_API_KEY=' "$HOME/.hermes/.env" | cut -d= -f2-)
fi
if [ -z "$KEY" ]; then
  echo "$(date '+%F %T') FAIL no-api-key" >> "$LOG"
  exit 1
fi

TS=$(date '+%F %T')
OUT=$(mktemp)
CODE=$(curl -sS -m "$TIMEOUT" -o "$OUT" -w "%{http_code} %{time_total}" \
  -X POST http://127.0.0.1:20128/v1/chat/completions \
  -H "Content-Type: application/json" -H "Authorization: Bearer $KEY" \
  -d '{"model":"kr/auto","messages":[{"role":"user","content":"balas satu kata: ok"}],"max_tokens":5}' 2>/dev/null)
CURL_EC=$?
HTTP=$(echo "$CODE" | awk '{print $1}')
SECS=$(echo "$CODE" | awk '{print $2}')

if [ $CURL_EC -ne 0 ]; then
  echo "$TS HANG curl_ec=$CURL_EC after=${SECS:-?}s" >> "$LOG"
elif [ "$HTTP" != "200" ]; then
  echo "$TS FAIL http=$HTTP time=${SECS}s" >> "$LOG"
elif grep -q '"content"' "$OUT" 2>/dev/null; then
  echo "$TS OK time=${SECS}s" >> "$LOG"
else
  echo "$TS FAIL empty-body http=$HTTP time=${SECS}s" >> "$LOG"
fi
rm -f "$OUT"
