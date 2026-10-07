-- ~/.config/hypr/custom/execs.lua

exec_once = {
    "swww-daemon",
    "ags run " .. os.getenv("HOME") .. "/.config/ags",
    -- restaura el último wallpaper (y su paleta) al iniciar sesión
    "bash -c 'set-wallpaper \"$(readlink -f ~/.cache/current-wallpaper)\"'",
}
