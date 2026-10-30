#!/usr/bin/env bash
#
# retheme.sh — regenera TODA la paleta a partir de un wallpaper y la aplica
# en vivo a lo que ya está corriendo.
#
# Uso:
#   retheme.sh /ruta/a/imagen.jpg
#
# Es el único punto de entrada para recolorear:
#   - waypaper (post_command)  -> retheme.sh $wallpaper
#   - wallpaper.sh (random/rofi) -> retheme.sh $WALLPAPER
#
# Requiere: matugen, hyprctl, kitty, fish, waybar, swaync.
set -u

IMAGE="${1:-}"
if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
	notify-send "Tema" "No se pudo recolorear: imagen no válida ($IMAGE)" -a "Retheme"
	exit 1
fi

# 1) Regenerar todas las plantillas (kitty, fish, waybar, rofi, nwgbar,
#    swaync, hyprland, hyprlock) a partir de esta imagen.
if command -v matugen &>/dev/null; then
	matugen image "$IMAGE" --source-color-index 0 || {
		notify-send "Tema" "matugen falló al generar la paleta" -a "Retheme"
		exit 1
	}
else
	notify-send "Tema" "matugen no está instalado (sin recoloreo)" -a "Retheme"
	exit 1
fi

# 2) Empujar los colores en vivo a las apps que ya están corriendo.
"$HOME/.config/hypr/hyprland/scripts/apply-theme.sh"

# 3) Parchear los colores directamente en style.css y recargar waybar SUAVEMENTE
#    (sin matar el proceso — evita el freeze visual del @import)
"$HOME/.config/hypr/hyprland/scripts/waybar-update-colors.sh"

notify-send "Tema" "Colores aplicados a todo el sistema" -a "Retheme"