# Local AI

## Endpoint yang dipakai

- 9router (OpenAI-compatible): `http://127.0.0.1:20128/v1` — dashboard `:20128/dashboard`.
  Service: `systemd/9router-mibp.service` (`DATA_DIR=~/.9router`). DB kredensial
  `~/.9router/db/data.sqlite` TIDAK dibackup di git — restore terenkripsi manual, `chmod 600`.
- llama.cpp lokal: `:1234` chat (Qwen2.5-Coder-7B Q4_K_M), `:1235` autocomplete
  (Qwen2.5-Coder-1.5B Q8_0). Lihat `scripts/start-llama-servers.sh` + `systemd/llama-servers.service`.
  Catatan: pastikan file `.gguf` ada sebelum start (model tidak dibackup).
- LM Studio: app terinstall; `~/.lmstudio/models/` saat ini kosong (model via llama.cpp).
  Bundled: `nomic-embed-text-v1.5.Q4_K_M` (embeddings).
- OpenCode: `opencode/` — default `lmstudio/qwen3.5-9b`; provider 9router via baseURL di atas.

## Model inventory

Lihat `../local-ai/models.md` (nama saja, tanpa file).

## Build llama.cpp (penting)

```bash
git clone https://github.com/ggerganov/llama.cpp.git ~/llama.cpp
cmake -B ~/llama.cpp/build -DGGML_CUDA=ON && cmake --build ~/llama.cpp/build -j
```

Flags runtime penting: `-ngl 99` (full GPU offload, RTX 2060S 8GB), `-fa on`,
`-c 2048`, `--cache-reuse 256`. Lihat `nvidia.md` untuk OOM guidance.
