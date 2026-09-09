--- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
    hl.exec_cmd("waybar")
    -- hyprpaper: si waypaper ya está configurado con backend=hyprpaper, esto es
    -- redundante (waypaper lo levanta solo). Lo dejamos explícito igual por si
    -- waypaper no arranca a tiempo o cambiás de backend más adelante.
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waypaper")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor volantes_cursors 24")
    
    -- gpu-screen-recorder
    hl.exec_cmd("com.dec05eba.gpu_screen_recorder")
    
    --notify
    hl.exec_cmd("swaync")
   -- Necesario para que xdg-desktop-portal (y Discord screen share) funcione en Wayland
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland DISPLAY") 
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY PATH")
    hl.exec_cmd("~/.config/hypr/xdg-portal.sh")

end)
