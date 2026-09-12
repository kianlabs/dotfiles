local home = os.getenv("HOME")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 2; setsid -f waybar -c " .. home .. "/.config/waybar/config.jsonc -s " .. home .. "/.config/waybar/style.css >/tmp/waybar-autostart.log 2>&1")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sleep 1 && QT_QPA_PLATFORM=wayland qs")
    hl.exec_cmd("pkill awww-daemon 2>/dev/null; sleep 1; rm -f /run/user/1000/wayland-1-awww-daemon.sock; awww-daemon & sleep 1; awww img '" .. home .. "/Pictures/wallpapers/vagabond.jpg' >/dev/null 2>&1 &")
    hl.exec_cmd("sleep 2; matugen image '" .. home .. "/Pictures/wallpapers/vagabond.jpg' --prefer darkness >/dev/null 2>&1 &")
    hl.exec_cmd("sleep 3; rustdesk --server >/tmp/rustdesk-server.log 2>&1 &")
end)
