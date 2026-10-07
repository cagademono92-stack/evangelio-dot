#!/usr/bin/env bash
#
# WaybarThemeSwitch.sh — selector de temas para waybar + rofi.
#
# Muestra un menú con rofi listando los temas de ~/.config/waybar/style/*.css.
# Al elegir uno:
#   - copia el CSS elegido a ~/.config/waybar/style.css
#   - copia el config (layout: top/left/dock/...) desde ~/.config/waybar/configs/ si el tema lo define
#   - apunta el @theme de ~/.config/rofi/config.rasi a ~/.config/rofi/themes/theme-<slug>.rasi
#   - reinicia waybar (igual que hace matugen al recargar colores)
#
# Requiere: rofi, waybar. Sin dependencias extra.

WAYBAR_STYLE_DIR="$HOME/.config/waybar/style"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
WAYBAR_CONFIG_DIR="$HOME/.config/waybar/configs"
ROFI_THEME_DIR="$HOME/.config/rofi/themes"
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
ROFI_THEME_PICKER="$HOME/.config/rofi/config-themes.rasi"

# name del archivo CSS -> slug del tema (empareja con rofi/themes/theme-<slug>.rasi)
declare -A THEME_SLUG=(
	["[Default] Simple Pink"]="default"
	["[BOTTOM] macOS Dock"]="macos"
	["[TOP] Matrix Code"]="matrix"
	["[BOTTOM] Aurora Glass"]="aurora"
	["[Dock] Muelle Flotante"]="dock"
	["[Top] Segmentos"]="segmentos"
	["[Minimal] Espectro"]="espectro"
	["[Top] Cristal"]="cristal"
	["[BOTTOM] Dock Neon"]="neon"
	["[Top] Azulejos"]="azulejos"
	["[Top] Contorno"]="contorno"
	["[Top] Minecraft"]="minecraft"
)

# slug -> color de acento (para la bolitita de color en el menú)
declare -A THEME_DOT=(
	["default"]="#81d3de"
	["macos"]="#c9d6e3"
	["matrix"]="#00ff41"
	["aurora"]="#7dd3fc"
	["dock"]="#a78bfa"
	["segmentos"]="#f472b6"
	["espectro"]="#67e8f9"
	["cristal"]="#7dd3fc"
	["neon"]="#f0abfc"
	["azulejos"]="#f9a8d4"
	["contorno"]="#a5b4fc"
	["minecraft"]="#7cbd6b"
)

# slug -> config de waybar (layout). Los temas que no están usan el TOP por defecto.
# La config cambia position/width/módulos para que el layout acompañe al CSS.
declare -A THEME_CONFIG=(
	["macos"]="[BOTTOM] macOS Dock"
	["matrix"]="[TOP] Matrix Code"
	["aurora"]="[BOTTOM] Aurora Glass"
	["dock"]="[BOTTOM] Dock Flotante"
	["segmentos"]="[TOP] Segmentado"
	["espectro"]="[TOP] Minimal Espectro"
	["cristal"]="[TOP] Minimal"
	["neon"]="[BOTTOM] Dock Neon"
	["azulejos"]="[TOP] Segmentado"
	["contorno"]="[TOP] Minimal Espectro"
	["minecraft"]="[TOP] Segmentado"
)

DEFAULT_CONFIG="[TOP] Minimal"

if [ ! -d "$WAYBAR_STYLE_DIR" ]; then
	notify-send "Temas" "No existe la carpeta $WAYBAR_STYLE_DIR" -a "Waybar"
	exit 1
fi

# Lista (paralela) de temas: filas (con bolitita de color) + slug + archivo css.
rows=()
slugs=()
css_files=()

while IFS= read -r file; do
	[ -f "$file" ] || continue
	name=$(basename "$file" .css)
	slug="${THEME_SLUG[$name]:-}"
	[ -n "$slug" ] || continue
	dot="${THEME_DOT[$slug]:-#777777}"
	rows+=("<span foreground=\"$dot\">● </span>$name")
	slugs+=("$slug")
	css_files+=("$file")
done < <(find "$WAYBAR_STYLE_DIR" -maxdepth 1 -type f -name "*.css" | sort)

if [ ${#rows[@]} -eq 0 ]; then
	notify-send "Temas" "No hay ningún tema en $WAYBAR_STYLE_DIR" -a "Waybar"
	exit 1
fi

# -format i => rofi devuelve solo el índice (0-based) del tema elegido.
choice=$(printf '%s\n' "${rows[@]}" | rofi -theme "$ROFI_THEME_PICKER" -dmenu -i -format i -p "Temas")

# El usuario canceló (Esc) -> no es error.
[ -n "$choice" ] || exit 0

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#rows[@]}" ]; then
	notify-send "Temas" "Selección inválida" -a "Waybar"
	exit 1
fi

slug="${slugs[$choice]}"
name="${rows[$choice]##*</span>}"   # sin el span de la bolitita (solo para notificar)
css_file="${css_files[$choice]}"
rasi_file="$ROFI_THEME_DIR/theme-$slug.rasi"

if [ ! -f "$rasi_file" ]; then
	notify-send "Temas" "No encontré $rasi_file (faltan los colores de rofi)" -a "Waybar"
	exit 1
fi

cp "$css_file" "$WAYBAR_STYLE"

# Aplicar el config (layout) del tema; los clásicos usan el TOP por defecto.
config_name="${THEME_CONFIG[$slug]:-$DEFAULT_CONFIG}"
config_file="$WAYBAR_CONFIG_DIR/$config_name"
if [ -f "$config_file" ]; then
	cp "$config_file" "$HOME/.config/waybar/config"
	layout="$config_name"
else
	layout="(config actual)"
	notify-send "Temas" "No encontré $config_file, mantengo el layout actual" -a "Waybar"
fi

# Apuntar el @theme activo de rofi al tema elegido (solo la línea no comentada).
if [ -f "$ROFI_CONFIG" ]; then
	sed -i "s|^@theme .*|@theme \"$rasi_file\"|" "$ROFI_CONFIG"
fi

# Recargar waybar (mismo método que usa la post_hook de matugen).
pkill waybar; sleep 0.3; waybar & disown

notify-send "Tema aplicado" "waybar: $name\nlayout: $layout\nrofi: theme-$slug" -a "Waybar"