# Hermes restore + MCP patch notes

Detail profil: lihat `hermes/README.md`.

## Patch lokal Hermes MCP (`tools/mcp_tool.py`)

Upstream mengimpor SDK `mcp` (~260ms, 60ms hanya `mcp.types`) di setiap startup CLI
meski tanpa MCP server. Patch lokal membuatnya lazy:

- Probe ketersediaan via `importlib.util.find_spec("mcp")` (~1ms, tanpa eksekusi modul).
- Simbol SDK di-bind saat pertama dipakai oleh `_ensure_mcp_sdk()` (idempoten, thread-safe,
  hormat pada mock test: `_MCP_AVAILABLE=False` tambalan test tidak diimpor ulang).
- Akses atribut luar via module `__getattr__` (PEP 562) untuk simbol di `_MCP_SDK_LAZY_SYMBOLS`.

Reproduksi setelah fresh checkout Hermes: terapkan pola di atas di sekitar blok import
`mcp` di `tools/mcp_tool.py` (lihat komentar `LAZY (see _ensure_mcp_sdk)` sebagai jangkar),
atau ambil file dari upstream bila sudah di-merge. Seluruh source tree Hermes TIDAK dibackup.

## Pin versi

- `pydantic==2.13.4`, `mcp==2.0.0` di venv Hermes (`~/.hermes/hermes-agent/venv`).
  Bila MCP error setelah update venv: `pip install 'pydantic==2.13.4' 'mcp==2.0.0'`.

## Cron (dokumentasi, bukan copy)

`cron/jobs.json` berisi runtime state → daftarkan ulang via bot:

- Pulse: `pulse-morning-brief` 07:30, `pulse-evening-recap` 18:30 (WIB, tiap hari)
- Astro: `daily-learning-reminder` 08:00 harian, `weekly-progress-review` Minggu 09:00,
  `friday-interview-prep` Jumat 19:00
- Admin Sol: `weekly-discord-hermes-health` Minggu 01:00
