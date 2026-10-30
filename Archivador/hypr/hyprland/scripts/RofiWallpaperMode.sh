#!/usr/bin/env bash
#
# RofiWallpaperMode.sh — modo rofi "wallpaper" (script mode) integrado.
# Muestra las imágenes de ~/Pictures/wallpapers con miniaturas y, al elegir
# una, la aplica con hyprpaper + matugen reusando ~/.../wallpaper.sh (el mismo
# script que usa el bind de wallpaper random).
#
# Protocolo rofi script mode (rofi-script(5)):
#   - Sin argumentos (ROFI_RETV=0): imprime la lista.
#   - Con el texto elegido como $1 (ROFI_RETV=1): aplica y sale.
#   - Si el script no imprime nada, rofi se cierra.
#
# Requiere: rofi (script mode), hyprpaper, matugen

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
WALLPAPER_SCRIPT="$HOME/.config/hypr/hyprland/scripts/wallpaper.sh"

list_wallpapers() {
	# defino el prompt del modo
	printf '\0prompt\x1f🖼️  Wallpaper\n'

	if [ ! -d "$WALLPAPER_DIR" ]; then
		printf 'No existe la carpeta %s\0nonselectable\x1ftrue\n' "$WALLPAPER_DIR"
		return
	fi

	found=0
	while IFS= read -r -d '' path; do
		name=$(basename "$path")
		# icon => miniatura (ruta absoluta); info => ruta exacta para aplicar
		printf '%s\0icon\x1f%s\0info\x1f%s\n' "$name" "$path" "$path"
		found=$((found + 1))
	done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | sort -z)

	if [ "$found" -eq 0 ]; then
		printf 'No encontré imágenes en %s\0nonselectable\x1ftrue\n' "$WALLPAPER_DIR"
	fi
}

apply_wallpaper() {
	# ROFI_INFO trae la ruta exacta de la fila elegida (más robusto que re-hacer
	# matching con el nombre mostrado, que puede venir filtrado).
	local path="$ROFI_INFO"

	if [ -z "$path" ] && [ -n "$1" ]; then
		path="$WALLPAPER_DIR/$1"
		[ -f "$path" ] || path=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f -name "$1" | head -n1)
	fi

	if [ -z "$path" ] || [ ! -f "$path" ]; then
		exit 0
	fi

	if [ ! -x "$WALLPAPER_SCRIPT" ]; then
		notify-send "Wallpaper" "No encontré o no es ejecutable: $WALLPAPER_SCRIPT" -a "Hyprland"
		exit 0
	fi

	# Lo lanzo desacoplado (stdin/stdout/stderr a /dev/null y en segundo plano)
	# para que rofi no se quede esperando que termine matugen: se cierra al instante.
	(
		setsid "$WALLPAPER_SCRIPT" "$path" > /dev/null 2>&1
	) & disown

	# sin salida => rofi quita este modo y se cierra
	exit 0
}

case "${ROFI_RETV:-0}" in
	0) list_wallpapers ;;
	1) apply_wallpaper "$1" ;;
	*) exit 0 ;;
esac