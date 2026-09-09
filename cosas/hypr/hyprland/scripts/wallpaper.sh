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

# hyprpaper se controla por IPC (no por config estático) para cambios en caliente
hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper ",$WALLPAPER"

# Regenerar colores de waybar/rofi/fish a partir de esta imagen
matugen image "$WALLPAPER"

notify-send "Wallpaper" "Cambiado y recoloreado" -a "Hyprland"
