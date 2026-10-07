#!/usr/bin/env bash
#
# waybar-update-colors.sh — Actualiza los colores en style.css parcheando
# directamente los valores, en vez de usar @import "colors.css" que NO se
# recarga en vivo cuando el archivo cambia.
#
# Se llama DESPUÉS de que matugen regenera colors.css.
#
# Requiere: sed, grep

set -u

STYLE_CSS="$HOME/.config/waybar/style.css"
COLORS_CSS="$HOME/.config/waybar/colors.css"

if [ ! -f "$COLORS_CSS" ]; then
	exit 0
fi

# Leer los colores del archivo generado por matugen
bg=$(grep -oP '@define-color background \K#[0-9a-fA-F]+' "$COLORS_CSS" | head -1)
fg=$(grep -oP '@define-color foreground \K#[0-9a-fA-F]+' "$COLORS_CSS" | head -1)
accent=$(grep -oP '@define-color accent \K#[0-9a-fA-F]+' "$COLORS_CSS" | head -1)
accent_bright=$(grep -oP '@define-color accent-bright \K#[0-9a-fA-F]+' "$COLORS_CSS" | head -1)
border=$(grep -oP '@define-color border \K#[0-9a-fA-F]+' "$COLORS_CSS" | head -1)
alert=$(grep -oP '@define-color alert \K#[0-9a-fA-F]+' "$COLORS_CSS" | head -1)

# Si no se encontraron colores, salir
if [ -z "$bg" ] || [ -z "$fg" ]; then
	exit 0
fi

# Usar un archivo temporal para reemplazar los colores
TMPFILE=$(mktemp)
awk -v bg="$bg" -v fg="$fg" -v accent="$accent" \
	-v accent_bright="$accent_bright" -v border="$border" -v alert="$alert" '
{
	line = $0
	# Reemplazar @define-color con los valores actuales
	gsub(/@define-color background [^;]+;/, "@define-color background " bg ";", line)
	gsub(/@define-color foreground [^;]+;/, "@define-color foreground " fg ";", line)
	gsub(/@define-color accent [^;]+;/, "@define-color accent " accent ";", line)
	gsub(/@define-color accent-bright [^;]+;/, "@define-color accent-bright " accent_bright ";", line)
	gsub(/@define-color border [^;]+;/, "@define-color border " border ";", line)
	gsub(/@define-color alert [^;]+;/, "@define-color alert " alert ";", line)
	print line
}
' "$STYLE_CSS" > "$TMPFILE"

mv "$TMPFILE" "$STYLE_CSS"

# Recargar waybar suavemente (sin matar el proceso)
# SIGUSR1 hace que waybar recargue el CSS sin reiniciarse
pkill -USR1 -x waybar 2>/dev/null || true
