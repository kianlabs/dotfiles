#!/usr/bin/env bash

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backups/dotfiles-$(date +%Y%m%d-%H%M%S)"

COMPONENTS=(
    hypr
    waybar
    kitty
    nvim
    rofi
    mako
    cava
    matugen
)

# Safe to auto-enable on fresh install (local UI helpers only).
# Gateway/9router/tailscale/llama units are restored but NEVER auto-enabled here.
SAFE_ENABLE_UNITS=(
    mako.service
)

PACMAN_PACKAGES=(
    hyprland
    waybar
    kitty
    neovim
    rofi
    mako
    cava
    btop
    thunar
    wl-clipboard
    cliphist
    pipewire
    wireplumber
    brightnessctl
    hypridle
    hyprlock
    networkmanager
    bluez
    bluez-utils
    lm_sensors
    libnotify
    polkit
    hyprpolkitagent
    ttf-jetbrains-mono-nerd
    git
    zsh
    starship
    nodejs
    npm
    python
    python-pip
    uv
    tailscale
)

AUR_PACKAGES=(
    quickshell
    matugen-bin
    python-pywal16
    awww
    hyprshot
    visual-studio-code-bin
    rustdesk-bin
)

print_header() {
    clear
    echo
    echo "╭──────────────────────────────────────╮"
    echo "│     Arch + Hyprland Dotfiles         │"
    echo "╰──────────────────────────────────────╯"
    echo
}

pause() {
    echo
    read -r -p "Press Enter to continue..."
}

is_arch() {
    [[ -f /etc/arch-release ]]
}

install_pacman_packages() {
    echo
    echo "==> Installing official Arch packages..."
    echo

    sudo pacman -Syu --needed "${PACMAN_PACKAGES[@]}"

    if [[ $? -ne 0 ]]; then
        echo
        echo "⚠ Some official packages failed to install."
        echo "The installer will continue."
    fi
}

install_aur_packages() {
    echo
    echo "==> Installing AUR packages..."
    echo

    if command -v yay >/dev/null 2>&1; then
        yay -S --needed "${AUR_PACKAGES[@]}"
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        paru -S --needed "${AUR_PACKAGES[@]}"
        return
    fi

    echo "⚠ No AUR helper found."
    echo
    echo "Install these packages manually:"
    printf '  - %s\n' "${AUR_PACKAGES[@]}"
    echo
}

backup_component() {
    local component="$1"
    local target="$CONFIG_DIR/$component"

    if [[ -e "$target" ]]; then
        echo "Backup: $target"

        if ! mkdir -p "$BACKUP_DIR"; then
            echo "✗ Failed to create backup directory."
            return 1
        fi

        if ! cp -a "$target" "$BACKUP_DIR/$component"; then
            echo "✗ Failed to backup $component."
            echo "Installation aborted to protect your existing config."
            return 1
        fi

        echo "✓ Backup successful: $component"
    fi

    return 0
}

install_component() {
    local component="$1"
    local source="$REPO_DIR/$component"
    local target="$CONFIG_DIR/$component"

    if [[ ! -d "$source" ]]; then
        echo "⚠ Skipping $component: not found in repository."
        return 0
    fi

    if ! backup_component "$component"; then
        echo "✗ Installation of $component aborted."
        return 1
    fi

    if ! rm -rf "$target"; then
        echo "✗ Failed to remove existing $component config."
        return 1
    fi

    if ! cp -a "$source" "$target"; then
        echo "✗ Failed to install $component."

        rm -rf "$target"

        if [[ -e "$BACKUP_DIR/$component" ]]; then
            echo "Attempting automatic restore..."

            if cp -a "$BACKUP_DIR/$component" "$target"; then
                echo "✓ Previous $component config restored."
            else
                echo "✗ Automatic restore failed."
                echo "Backup is still available at:"
                echo "  $BACKUP_DIR/$component"
            fi
        fi

        return 1
    fi

    echo "✓ Installed $component"
    return 0
}

install_all_configs() {
    echo
    echo "==> Installing configs..."
    echo
    echo "Backup directory:"
    echo "  $BACKUP_DIR"
    echo

    mkdir -p "$CONFIG_DIR"

    for component in "${COMPONENTS[@]}"; do
        install_component "$component"
    done

    chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true

    /usr/bin/find "$CONFIG_DIR/hypr/scripts" \
        -type f -name '*.sh' \
        -exec chmod +x {} \; \
        2>/dev/null || true

    /usr/bin/find "$CONFIG_DIR/rofi" \
        -type f -name '*.sh' \
        -exec chmod +x {} \; \
        2>/dev/null || true
}

generate_colors() {
    echo
    echo "==> Checking generated colors..."

    mkdir -p "$HOME/.cache/wal"

    if [[ ! -f "$HOME/.cache/wal/colors-waybar.css" ]]; then
        echo
        echo "⚠ Pywal colors have not been generated yet."
        echo
        echo "Generate them with:"
        echo
        echo "  wal -i /path/to/wallpaper.jpg"
    else
        echo "✓ Existing Pywal palette found."
    fi
}

enable_services() {
    echo
    echo "==> Enabling services..."

    sudo systemctl enable NetworkManager.service 2>/dev/null || true
    sudo systemctl enable bluetooth.service 2>/dev/null || true

    echo "✓ Services configured"
}

check_commands() {
    echo
    echo "==> Dependency check"
    echo

    local commands=(
        hyprland
        waybar
        kitty
        nvim
        rofi
        mako
        cava
        btop
        thunar
        wl-copy
        wl-paste
        cliphist
        wpctl
        brightnessctl
        hypridle
        hyprlock
        nmcli
        sensors
        notify-send
        qs
        matugen
        awww
        hyprshot
        wal
    )

    for command_name in "${commands[@]}"; do
        printf '%-20s' "$command_name"

        if command -v "$command_name" >/dev/null 2>&1; then
            echo "✓"
        else
            echo "MISSING"
        fi
    done
}

backup_home_file() {
    local rel="$1"
    local target="$HOME/$rel"

    if [[ -e "$target" ]]; then
        mkdir -p "$BACKUP_DIR/home" || return 1
        echo "Backup: $target"
        cp -a "$target" "$BACKUP_DIR/home/$(echo "$rel" | tr '/' '_')" || return 1
    fi

    return 0
}

install_home_file() {
    local rel="$1"
    local source="$REPO_DIR/$2"
    local target="$HOME/$rel"

    if [[ ! -e "$source" ]]; then
        echo "Skipping $rel: not found in repository."
        return 0
    fi

    backup_home_file "$rel" || { echo "Aborted to protect $target."; return 1; }
    rm -rf "$target"
    cp -a "$source" "$target" && echo "Installed $rel"
}

install_home_files() {
    echo
    echo "==> Installing home files (zsh/git/vscode/opencode)..."
    echo

    install_home_file ".zshrc" "zsh/zshrc"
    install_home_file ".p10k.zsh" "zsh/p10k.zsh"
    install_home_file ".gitconfig" "git/gitconfig"
    install_home_file "opencode.json" "opencode/opencode-home.json"

    if [[ -d "$REPO_DIR/zsh/zshrc.d" ]]; then
        mkdir -p "$HOME/.config"
        backup_home_file ".config/zshrc.d" || return 1
        rm -rf "$HOME/.config/zshrc.d"
        cp -a "$REPO_DIR/zsh/zshrc.d" "$HOME/.config/zshrc.d" && echo "Installed .config/zshrc.d"
    fi

    mkdir -p "$HOME/.config/Code/User"
    backup_home_file ".config/Code/User/settings.json" || return 1
    if [[ -f "$REPO_DIR/vscode/settings.json" ]]; then
        cp -a "$REPO_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json" \
            && echo "Installed VS Code settings.json"
    fi

    if [[ -d "$REPO_DIR/opencode/skills" ]]; then
        mkdir -p "$HOME/.config/opencode"
        cp -a "$REPO_DIR/opencode/skills" "$HOME/.config/opencode/skills" 2>/dev/null \
            && echo "Installed opencode skills"
        cp -a "$REPO_DIR/opencode/plugins" "$HOME/.config/opencode/plugins" 2>/dev/null \
            && echo "Installed opencode plugins"
    fi

    for f in opencode.json opencode.jsonc tui.jsonc; do
        if [[ -f "$REPO_DIR/opencode/$f" ]]; then
            backup_home_file ".config/opencode/$f" || return 1
            mkdir -p "$HOME/.config/opencode"
            cp -a "$REPO_DIR/opencode/$f" "$HOME/.config/opencode/$f" \
                && echo "Installed .config/opencode/$f"
        fi
    done
}

install_repo_scripts() {
    echo
    echo "==> Installing helper scripts to ~/.local/bin ..."
    echo

    mkdir -p "$HOME/.local/bin"

    for s in "$REPO_DIR"/scripts/*.sh; do
        [[ -e "$s" ]] || continue
        cp -a "$s" "$HOME/.local/bin/" && chmod +x "$HOME/.local/bin/$(basename "$s")"
        echo "Installed $(basename "$s")"
    done
}

restore_packages() {
    echo
    echo "==> Restoring packages from inventory..."
    echo

    if ! is_arch; then
        echo "Not Arch Linux, skipping."
        return
    fi

    if [[ -f "$REPO_DIR/packages/pacman-official.txt" ]]; then
        sudo pacman -S --needed - < "$REPO_DIR/packages/pacman-official.txt" || \
            echo "Some official packages failed, continuing."
    fi

    if [[ -f "$REPO_DIR/packages/aur.txt" ]]; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed - < "$REPO_DIR/packages/aur.txt" || \
                echo "Some AUR packages failed, continuing."
        else
            echo "yay not found, skipping AUR list."
        fi
    fi

    if [[ -f "$REPO_DIR/vscode/extensions.txt" ]] && command -v code >/dev/null 2>&1; then
        while IFS= read -r ext; do
            [[ -n "$ext" ]] && code --install-extension "$ext" --force >/dev/null 2>&1 || true
        done < "$REPO_DIR/vscode/extensions.txt"
        echo "VS Code extensions restored."
    fi
}

restore_systemd_units() {
    echo
    echo "==> Restoring systemd user units (NO auto-enable except safe list)..."
    echo

    mkdir -p "$HOME/.config/systemd/user"

    for u in "$REPO_DIR"/systemd/*.service "$REPO_DIR"/systemd/*.timer \
             "$REPO_DIR"/hermes/systemd/*.service; do
        [[ -e "$u" ]] || continue
        cp -a "$u" "$HOME/.config/systemd/user/" && echo "Restored $(basename "$u")"
    done

    systemctl --user daemon-reload 2>/dev/null || true

    for u in "${SAFE_ENABLE_UNITS[@]}"; do
        systemctl --user enable "$u" 2>/dev/null && echo "Enabled $u" || true
    done

    echo
    echo "Enable the rest MANUALLY after secrets are in place, e.g.:"
    echo "  systemctl --user enable --now 9router-mibp.service"
    echo "  systemctl --user enable --now hermes-gateway-agent-discord.service"
}

restore_backup() {    echo
    echo "Available backups:"
    echo

    if [[ ! -d "$HOME/.config-backups" ]]; then
        echo "No backups found."
        return
    fi

    ls -1 "$HOME/.config-backups"

    echo
    read -r -p "Backup folder name: " backup_name

    local selected="$HOME/.config-backups/$backup_name"

    if [[ ! -d "$selected" ]]; then
        echo "Backup not found."
        return
    fi

    echo
    echo "Restoring from:"
    echo "  $selected"

    for component in "${COMPONENTS[@]}"; do
        if [[ -e "$selected/$component" ]]; then
            rm -rf "$CONFIG_DIR/$component"

            if cp -a "$selected/$component" "$CONFIG_DIR/$component"; then
                echo "✓ Restored $component"
            else
                echo "✗ Failed to restore $component"
            fi
        fi
    done
}

full_install() {
    if ! is_arch; then
        echo "⚠ This installer is intended for Arch Linux."
        echo "Installation cancelled."
        return
    fi

    echo "This will:"
    echo
    echo "  • install required packages"
    echo "  • back up existing configs"
    echo "  • install the dotfiles"
    echo "  • enable NetworkManager/Bluetooth"
    echo
    echo "Existing configs are backed up before replacement."
    echo

    read -r -p "Continue? [y/N] " answer

    case "$answer" in
        y|Y)
            ;;
        *)
            echo "Cancelled."
            return
            ;;
    esac

    install_pacman_packages
    install_aur_packages
    install_all_configs
    install_home_files
    install_repo_scripts
    restore_systemd_units
    enable_services
    generate_colors
    check_commands

    echo
    echo "╭──────────────────────────────────────╮"
    echo "│        Installation complete         │"
    echo "╰──────────────────────────────────────╯"
    echo
    echo "Backup:"
    echo "  $BACKUP_DIR"
    echo
    echo "Log out and start Hyprland when ready."
}

install_single() {
    print_header

    echo "Available components:"
    echo
    echo "1) Hyprland"
    echo "2) Waybar"
    echo "3) Kitty"
    echo "4) Neovim"
    echo "5) Rofi"
    echo "6) Mako"
    echo "7) Cava"
    echo

    read -r -p "Select: " choice

    case "$choice" in
        1) install_component hypr ;;
        2) install_component waybar ;;
        3) install_component kitty ;;
        4) install_component nvim ;;
        5) install_component rofi ;;
        6) install_component mako ;;
        7) install_component cava ;;
        *) echo "Invalid selection." ;;
    esac
}

while true; do
    print_header

    echo "1) Full installation"
    echo "2) Install one component"
    echo "3) Install dependencies only"
    echo "4) Check dependencies"
    echo "5) Restore backup"
    echo "6) Restore packages from inventory"
    echo "7) Restore systemd units (no risky enable)"
    echo "8) Install home files (zsh/git/vscode/opencode)"
    echo "0) Exit"
    echo

    read -r -p "Select an option: " choice

    case "$choice" in
        1)
            full_install
            pause
            ;;
        2)
            install_single
            pause
            ;;
        3)
            install_pacman_packages
            install_aur_packages
            pause
            ;;
        4)
            check_commands
            pause
            ;;
        5)
            restore_backup
            pause
            ;;
        6)
            restore_packages
            pause
            ;;
        7)
            restore_systemd_units
            pause
            ;;
        8)
            install_home_files
            install_repo_scripts
            pause
            ;;
        0)
            echo "Bye."
            exit 0
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done
