# Remote / network access

## Tailscale (userspace, tanpa root)

- Paket: `tailscale` (repo official) + unit `systemd/tailscaled.service`:
  `~/.local/tailscale/bin/tailscaled --tun=userspace-networking`,
  state di `~/.local/tailscale/state/` (JANGAN backup state/secret).
- Setup: `tailscale up` (login browser, tanpa auth key di repo).
- Jangan commit: auth key, `tailscaled.state`.

## RustDesk

- Binary terinstall. Config `~/.config/rustdesk/*.toml` MENGANDUNG password/keys
  → TIDAK dibackup. Catat manual: ID server, relay bila pakai self-hosted.
- Setelah reinstall: install paket, set password manual, verifikasi koneksi.

## SSH

- Service: enable `sshd` bila perlu remote masuk (`sudo systemctl enable --now sshd`).
- Jangan backup `~/.ssh` (private key). Public key didokumentasikan manual bila perlu.
- Jangan backup password Wi-Fi / NetworkManager secrets (`/etc/NetworkManager/system-connections/`).
