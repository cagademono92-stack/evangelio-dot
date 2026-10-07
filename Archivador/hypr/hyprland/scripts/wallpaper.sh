#!/usr/bin/env bash
#
# wallpaper.sh — setea un wallpaper vía hyprpaper y regenera los colores
# de waybar/rofi/fish con matugen.
#
# Uso:
#   wallpaper.sh /ruta/a/imagen.png   -> usa esa imagen puntual
#   wallpaper.sh                      -> elige una al azar de WALLPAPER_DIR
#
# Requiere: hyprpaper, matugen (yay -S hyprpaper matugen)

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

if [ -n "$1" ]; then
	WALLPAPER="$1"
else
	WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)
fi

if [ -z "$WALLPAPER" ]; then
	notify-send "Wallpaper" "No encontré ninguna imagen en $WALLPAPER_DIR" -a "Hyprland"
	exit 1
fi

# Persistir el último wallpaper en el config de waypaper, así "waypaper --restore"
# (que corre al inicio de sesión) vuelve a usar este fondo tras un reinicio.
WAYPAPER_CFG="$HOME/.config/waypaper/config.ini"
if [ -f "$WAYPAPER_CFG" ]; then
	sed -i "s|^wallpaper = .*|wallpaper = $WALLPAPER|" "$WAYPAPER_CFG"
fi

if ! command -v hyprctl &>/dev/null; then
	notify-send "Wallpaper" "hyprctl no está disponible" -a "Hyprland"
	exit 1
fi

if ! pgrep -x hyprpaper > /dev/null; then
	notify-send "Wallpaper" "hyprpaper no está corriendo, lo arranco..." -a "Hyprland"
	hyprpaper &
	sleep 1
fi

# hyprpaper 0.8.x acepta un solo request IPC "wallpaper" con argumentos
# [mon],[path],[fit_mode]. ¡OJO! El monitor tiene que ir SIEMPRE con su nombre
# explícito (p.ej. HDMI-A-1): con el monitor vacío (",/path") el request
# devuelve éxito pero NO cambia nada en pantalla ("no wp will be created").
for MON in $(hyprctl monitors | awk '/^Monitor/ {print $2}'); do
	hyprctl hyprpaper wallpaper "$MON,$WALLPAPER,fill" &
done
wait

# Mantener el último wallpaper como default del config de hyprpaper: si por lo
# que sea hyprpaper se reinicia solo (o IPC no disponible), levanta el último
# elegido en vez del default.png. Formato de hyprpaper >= 0.8 (bloques).
HYPRPAPER_CFG="$HOME/.config/hypr/hyprpaper.conf"
FIRST_MON=$(hyprctl monitors | awk '/^Monitor/ {print $2}' | head -n1)
{
	printf 'splash = false\nipc = on\n'
	printf '\nwallpaper {\n    monitor = %s\n    path = %s\n    fit_mode = fill\n}\n' "$FIRST_MON" "$WALLPAPER"
} > "$HYPRPAPER_CFG"

# Regenerar la paleta (matugen) y aplicarla en vivo a todo lo que ya corre
# (kitty, fish, waybar, swaync, nwg-bar, bordes de Hyprland) vía retheme.sh.
if command -v matugen &>/dev/null; then
	"$HOME/.config/hypr/hyprland/scripts/retheme.sh" "$WALLPAPER"
else
	notify-send "Wallpaper" "Cambiado, pero matugen no está instalado (sin recoloreo)" -a "Hyprland"
	exit 0
fi
