# Hermes configuration backup (sanitized)

Backup konfigurasi Hermes multi-profile. Live config tidak diubah saat backup ini dibuat.
Semua secret diganti placeholder `${...}` — isi manual setelah restore.

## Profile dan fungsi

| Profile | Bot | Fungsi |
|---|---|---|
| agent-discord | Astro | Software Engineering Coach (Python/JS/backend/Git) |
| agent-daily | Vision | Daily assistant, cepat dan conversational |
| agent-admin | Admin Sol | Discord server administrator (model diset manual, jangan ubah) |
| agent-security | Cipher | Security + automation, reasoning kuat |
| agent-news | Pulse | News/intelligence briefing (cron pagi + sore) |

## Lokasi live config

- Profile: `~/.hermes/profiles/agent-<nama>/config.yaml`
- Service: `~/.config/systemd/user/hermes-gateway-*.service`
- MCP server: `~/.hermes/profiles/agent-admin/tools/discord-admin-plus/server.py`

## Cara restore

```bash
# 1. copy config per profile (sudah termasuk model, fallback, channel, MCP)
cp dotfiles/hermes/profiles/agent-discord/config.yaml ~/.hermes/profiles/agent-discord/config.yaml
# ... ulangi untuk daily/admin/security/news

# 2. copy systemd services lalu reload
cp dotfiles/hermes/systemd/hermes-gateway-*.service ~/.config/systemd/user/
systemctl --user daemon-reload

# 3. copy MCP server
cp dotfiles/hermes/mcp/discord-admin-plus/server.py ~/.hermes/profiles/agent-admin/tools/discord-admin-plus/server.py

# 4. isi secret manual (JANGAN commit):
#    - DISCORD_BOT_TOKEN (env untuk MCP discord-admin-plus)
#    - HERMES_CUSTOM_LOCALHOST_20129_API_KEY (9router API key untuk model)
#    Lihat .env.example untuk daftar variable.

# 5. restart service yang direstore, satu per satu:
systemctl --user restart hermes-gateway-agent-discord.service
systemctl --user is-active hermes-gateway-agent-discord.service
```

## Cron penting (didokumentasikan, tidak dicopy mentah)

`cron/jobs.json` berisi runtime state (last_run, dispatch) sehingga tidak dibackup langsung.
Daftarkan ulang via bot/gateway bila hilang:

- Pulse (`agent-news`): `pulse-morning-brief` tiap hari 07:30 WIB, `pulse-evening-recap` tiap hari 18:30 WIB
- Astro (`agent-discord`): `daily-learning-reminder` tiap hari 08:00, `weekly-progress-review` Minggu 09:00, `friday-interview-prep` Jumat 19:00
- Admin Sol (`agent-admin`): `weekly-discord-hermes-health` Minggu 01:00

## Service systemd

| Service | Profile |
|---|---|
| hermes-gateway.service | gateway utama |
| hermes-gateway-agent-discord.service | Astro |
| hermes-gateway-agent-daily.service | Vision |
| hermes-gateway-agent-admin.service | Admin Sol |
| hermes-gateway-agent-security.service | Cipher |
| hermes-gateway-agent-news.service | Pulse |
| (+ agent-alpha / agent-beta: hanya unit file, config profile tidak dibackup) | — |

## Yang sengaja dikecualikan

- `.env` / token / API key / password / private key
- `SOUL.md` (persona, mungkin berisi info pribadi)
- `sessions/`, `logs/`, `memory/`/`memories/`, `workspace/`, `state.db*`
- `config.yaml.bak.*` (backup lama, mungkin berisi secret)
- `cron/jobs.json`, `executions.db`, `output/` (runtime state)
- `__pycache__/`, `*.pyc`
