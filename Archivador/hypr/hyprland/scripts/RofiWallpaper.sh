#!/usr/bin/env bash
#
# RofiWallpaper.sh — selector de wallpaper con miniaturas usando rofi.
# Al elegir una imagen, la aplica con hyprpaper y recolorea todo con matugen
# (reusa wallpaper.sh, el mismo script que ya usa el bind de wallpaper random).
#
# Requiere: rofi (con soporte -show-icons), hyprpaper, matugen

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
WALLPAPER_SCRIPT="$HOME/.config/hypr/hyprland/scripts/wallpaper.sh"

if [ ! -d "$WALLPAPER_DIR" ]; then
	notify-send "Wallpaper" "No existe la carpeta $WALLPAPER_DIR" -a "Hyprland"
	exit 1
fi

if [ ! -x "$WALLPAPER_SCRIPT" ]; then
	notify-send "Wallpaper" "No encontré o no es ejecutable: $WALLPAPER_SCRIPT" -a "Hyprland"
	exit 1
fi

mapfile -t entries < <(
	find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort
)

if [ ${#entries[@]} -eq 0 ]; then
	notify-send "Wallpaper" "No encontré imágenes en $WALLPAPER_DIR" -a "Hyprland"
	exit 1
fi

# Construimos la lista con printf, que sí interpreta \0 (separador nombre/metadata)
# y \x1f (separador antes de "icon") de forma confiable, byte a byte de verdad —
# a diferencia de armar el string a mano con += y después "echo -en".
build_menu() {
	for path in "${entries[@]}"; do
		name=$(basename "$path")
		printf '%s\0icon\x1f%s\n' "$name" "$path"
	done
}

selected_name=$(build_menu | rofi -dmenu -i -p "Wallpaper" -show-icons -theme-str 'listview { columns: 3; lines: 3; }')

if [ -z "$selected_name" ]; then
	# el usuario canceló (Esc), no es un error
	exit 0
fi

selected_path=""
for path in "${entries[@]}"; do
	if [ "$(basename "$path")" = "$selected_name" ]; then
		selected_path="$path"
		break
	fi
done

if [ -z "$selected_path" ]; then
	notify-send "Wallpaper" "No pude encontrar el archivo para: $selected_name" -a "Hyprland"
	exit 1
fi

"$WALLPAPER_SCRIPT" "$selected_path"
