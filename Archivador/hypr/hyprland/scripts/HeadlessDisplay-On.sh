#!/usr/bin/env bash
#
# HeadlessDisplay-On.sh — crea un monitor virtual (headless) al lado de tu
# pantalla real, para usar como "segundo monitor" al streamear con
# Sunshine/Moonlight (pantalla extendida, no espejo).
#
# Uso:
#   HeadlessDisplay-On.sh                    -> resolución por defecto (1080x2340@60)
#   HeadlessDisplay-On.sh 1920x1080@60        -> resolución custom (ej: la de tu teléfono)
#
# El nombre del headless (HEADLESS-2, HEADLESS-3, ...) lo asigna Hyprland
# solo y cambia cada vez, así que lo guardamos en un archivo de estado para
# poder sacarlo después sin adivinar.

STATE_FILE="/tmp/hypr-headless-display.name"
MODE="${1:-1080x2340@60}"

# Tu monitor real es HDMI-A-1 a 1280x720 (ver monitors.lua) — lo ponemos a
# la derecha, en x=1280. Si cambiás de monitor o resolución, ajustá esto.
PHYSICAL_WIDTH=1280
POSITION="${PHYSICAL_WIDTH}x0"

if [ -f "$STATE_FILE" ]; then
	notify-send "Segundo monitor" "Ya hay un headless activo ($(cat "$STATE_FILE")). Corré HeadlessDisplay-Off.sh primero si querés cambiar la resolución." -a "Hyprland"
	exit 0
fi

hyprctl output create headless

# Encontrar el nombre real que le puso Hyprland (incrementa cada sesión)
HEADLESS_NAME=$(hyprctl -j monitors | jq -r '.[] | select(.name | test("HEADLESS-"; "i")).name' | tail -n 1)

if [ -z "$HEADLESS_NAME" ]; then
	notify-send "Segundo monitor" "No pude crear el headless" -a "Hyprland"
	exit 1
fi

hyprctl keyword monitor "$HEADLESS_NAME,$MODE,$POSITION,1"
echo "$HEADLESS_NAME" > "$STATE_FILE"

notify-send "Segundo monitor" "Creado: $HEADLESS_NAME ($MODE)\nConfigurá Sunshine -> Output Name = $HEADLESS_NAME" -a "Hyprland"
