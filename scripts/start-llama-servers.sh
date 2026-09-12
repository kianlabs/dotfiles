#!/bin/bash
# Auto-start llama.cpp servers untuk codecompanion/continue.dev
# 7B = chat (port 1234), 1.5B = autocomplete (port 1235)

LLAMA_SERVER="$HOME/llama.cpp/build/bin/llama-server"
MODEL_7B="$HOME/.lmstudio/models/lmstudio-community/Qwen2.5-Coder-7B-Instruct-GGUF/Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf"
MODEL_1B="$HOME/.lmstudio/models/lmstudio-community/Qwen2.5-Coder-1.5B-Instruct-GGUF/Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf"

# Kill existing instances
pkill -f "llama-server.*1234" 2>/dev/null
pkill -f "llama-server.*1235" 2>/dev/null
sleep 1

# Start 7B chat model
$LLAMA_SERVER \
  -m "$MODEL_7B" \
  --port 1234 \
  --host 127.0.0.1 \
  -ngl 99 \
  -fa on \
  -c 2048 \
  -np 1 \
  --cache-reuse 256 \
  --log-disable &

# Wait for 7B to load before starting 1.5B
sleep 5

# Start 1.5B autocomplete model
$LLAMA_SERVER \
  -m "$MODEL_1B" \
  --port 1235 \
  --host 127.0.0.1 \
  -ngl 99 \
  -fa on \
  -c 1024 \
  -np 1 \
  --cache-reuse 128 \
  --log-disable &

echo "llama servers started: 7B@1234, 1.5B@1235"
