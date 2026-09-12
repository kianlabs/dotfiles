# Restore flow (fresh Arch)

## 1. Base install

1. Install Arch (archinstall, profile minimal + `yay` bootstrap bila perlu).
2. Clone repo: `git clone https://github.com/kianlabs/dotfiles.git ~/dotfiles && cd ~/dotfiles`
3. Jalankan installer: `./install.sh` (symlink dotfiles, install paket dari `packages/`, restore unit systemd + daemon-reload).
4. Reboot / relogin Hyprland.

## 2. Package restore

```bash
sudo pacman -S --needed - < packages/pacman-official.txt
yay -S --needed - < packages/aur.txt
code --install-extension $(cat vscode/extensions.txt)   # atau loop per baris
```

npm global (referensi, install bila perlu): lihat `packages/npm-global.txt`.

## 3. Dotfile restore

`install.sh` membuat symlink `~/.config/<app>` → `~/dotfiles/<app>` dan membackup file existing ke `~/.config-backups/`.
Komponen: hypr waybar kitty nvim rofi mako cava zsh git vscode opencode matugen.

## 4. Systemd user restore

Unit ada di `systemd/` (+ `hermes/systemd/`). `install.sh` mengcopy + `daemon-reload`;
enable manual hanya yang aman (lihat `docs/` masing-masing). Jangan enable service
legacy `9router.service` (konflik port dengan `9router-mibp.service`).

## 5. Hermes restore

Lihat `hermes/README.md`. Secret (`DISCORD_BOT_TOKEN`, `HERMES_CUSTOM_LOCALHOST_*`)
diisi manual — tidak pernah di-commit.

## 6. Secret setup manual

- `~/.hermes/.env` (lihat `hermes/.env.example`)
- `~/.9router` DB: restore file terenkripsi offline ke `~/.9router/db/data.sqlite`, `chmod 600`
- `gh auth login` untuk credential helper git
- 9router `.env` (`~/9router-mibp-version/.env`): JWT_SECRET, API_KEY_SECRET, MACHINE_ID_SALT

## 7. Yang TIDAK ikut restore otomatis

DB 9router, OAuth/session, wallpaper binary, model `.gguf`, cache, font binary,
password Wi-Fi/NetworkManager, kunci SSH privat, RustDesk password.
