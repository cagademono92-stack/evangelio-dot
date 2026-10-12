-- ~/.config/hypr/custom/execs.lua

exec_once = {
    "swww-daemon",
    "ags run " .. os.getenv("HOME") .. "/.config/ags",
    -- restaura el último wallpaper (y su paleta) al iniciar sesión
    "bash -c 'set-wallpaper \"$(readlink -f ~/.cache/current-wallpaper)\"'",
}

-- Dock estilo macOS, nativo Wayland. -d = se oculta solo y aparece al
-- mover el mouse al borde inferior. -i 38 = iconos, -w 10 = cantidad de
-- workspaces (coincide con workspaceGroupSize de hyprland/variables.lua).
--
-- Va con hl.exec_cmd y NO en exec_once de arriba a propósito: en esta build de
-- Hyprland (config en Lua) exec_once no llega a ejecutarse, mientras que
-- hl.exec_cmd es lo que usan waybar/hyprpaper/swaync en hyprland/execs.lua y sí
-- funciona. Con -d el arranque es idempotente: relanzarlo no mata la instancia
-- viva (el propio dock detecta el lock y la nueva instancia sale), así que
--aguanta recargas de Hyprland sin duplicarse.
hl.on("hyprland.start", function ()
    hl.exec_cmd("nwg-dock-hyprland -d -i 38 -w 10")
end)
