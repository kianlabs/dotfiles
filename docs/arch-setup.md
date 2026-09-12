# Arch setup notes (Hyprland workstation)

- Base: Arch Linux, Hyprland (config `hypr/`: `hyprland.conf`, `hyprland.lua`, `configs/*.lua`,
  `hyprlock.conf`, `hyprpaper.conf`), Waybar (`waybar/config.jsonc` + `style.css` + `scripts/`),
  Kitty, Rofi, Mako, Cava, matugen (palette ikut wallpaper).
- AUR helper: `yay` (22 paket AUR, lihat `packages/aur.txt`).
- Shell: zsh + Powerlevel10k (`zsh/p10k.zsh`), plugins autosuggestions/syntax-highlighting/fzf-tab,
  fzf + zoxide, starship (`zsh/starship.toml`), `zsh/zshrc.d/` (auto-Hypr, dots-hyprland, shortcuts).
- Wallpaper: `~/.config/wallpapers/` (113M, TIDAK di-commit). Script: `hypr/scripts/wallpapers/*.sh`;
  thumbs di `~/.cache/wallpaper-thumbs`.
- Fonts: user fonts di `~/.local/share/fonts` (cantarell, CaskaydiaCove, JetBrainsMono, MapleMono, …);
  install via paket font, bukan copy binary.
- `awww`/`awww-daemon` terinstall (paket), tanpa config file — wallpaper diatur via script hypr.
- Monitor/keybind/autostart: `hypr/configs/monitors.lua`, `keybinds.lua`, `autostart.lua`.
- `coffee-mode.sh` di `waybar/scripts/` (inhibit idle).
