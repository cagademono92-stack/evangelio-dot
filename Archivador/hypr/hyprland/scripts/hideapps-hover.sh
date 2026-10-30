#!/usr/bin/env bash
#
# hideapps-hover.sh — daemon de hover para el módulo de waybar "ocultar/ver apps".
#
# Waybar no puede ejecutar comandos nativos al pasar el cursor por un módulo,
# así que este script vigila la posición del cursor (hyprctl cursorpos) y cuando
# entra en la zona del icono (esquina izquierda de la barra) con apps ocultas,
# las restaura TODAS.
#
# La zona se calcula a partir de la config de waybar (width / position /
# margin-top) + el monitor principal, suponiendo el módulo a la izquierda del bar.
#
# Se arranca desde hyprland/execs.lua (ejecución una única vez).

CONF="$HOME/.config/waybar/config"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hideapps"
STATE_FILE="$STATE_DIR/state"
SCRIPT="$HOME/.config/hypr/hyprland/scripts/hideapps.sh"

[ -x "$SCRIPT" ] || exit 1

# Parámetros del bar (con fallbacks por si cambia la config)
BAR_WIDTH=$(grep -o '"width"[[:space:]]*:[[:space:]]*[0-9]*' "$CONF" | grep -o '[0-9]*' | head -1)
BAR_WIDTH=${BAR_WIDTH:-1050}
BAR_POS=$(grep -o '"position"[[:space:]]*:[[:space:]]*"[a-z]*"' "$CONF" | sed 's/.*"\([a-z]*\)".*/\1/' | head -1)
BAR_POS=${BAR_POS:-top}
MARGIN_TOP=$(grep -o '"margin-top"[[:space:]]*:[[:space:]]*[0-9]*' "$CONF" | grep -o '[0-9]*' | head -1)
MARGIN_TOP=${MARGIN_TOP:-0}

# Ancho de la zona de hover: el primer módulo de modules-left (el icono).
ZONE_W=75
# Altura aproximada de la barra (waybar reporta 35px + padding).
ZONE_H=45

get_mon() {
	hyprctl -j monitors 2>/dev/null | jq -r '.[0] | "\(.x) \(.y) \(.width) \(.height)"'
}

in_zone() {
	local cur_x cur_y mx my mw
	# hyprctl cursorpos devuelve "X, Y" (coma). Extraer ambos enteros.
	IFS=', ' read -r cur_x cur_y <<<"$(hyprctl cursorpos 2>/dev/null)"
	[ -n "$cur_x" ] || return 1

	read -r mx my mw _ <<<"$(get_mon)"
	case "$BAR_POS" in
		left)
			[ "$cur_x" -ge $((mx)) ] && [ "$cur_x" -le $((mx + ZONE_W)) ] &&
			[ "$cur_y" -ge $((my + MARGIN_TOP)) ] && [ "$cur_y" -le $((my + MARGIN_TOP + ZONE_H)) ]
			;;
		right)
			[ "$cur_x" -ge $((mx + mw - ZONE_W)) ] && [ "$cur_x" -le $((mx + mw)) ] &&
			[ "$cur_y" -ge $((my + MARGIN_TOP)) ] && [ "$cur_y" -le $((my + MARGIN_TOP + ZONE_H)) ]
			;;
		bottom)
			local mh
			mh=$(hyprctl -j monitors 2>/dev/null | jq -r '.[0].height')
			[ "$cur_x" -ge $((mx + (mw - BAR_WIDTH) / 2)) ] && [ "$cur_x" -le $((mx + (mw - BAR_WIDTH) / 2 + ZONE_W)) ] &&
			[ "$cur_y" -ge $((my + mh - ZONE_H)) ] && [ "$cur_y" -le $((my + mh)) ]
			;;
		top|*)
			[ "$cur_x" -ge $((mx + (mw - BAR_WIDTH) / 2)) ] && [ "$cur_x" -le $((mx + (mw - BAR_WIDTH) / 2 + ZONE_W)) ] &&
			[ "$cur_y" -ge $((my + MARGIN_TOP)) ] && [ "$cur_y" -le $((my + MARGIN_TOP + ZONE_H)) ]
			;;
	esac
}

# Solo llamamos a show cuando hay apps ocultas (state con contenido).
loop() {
	while :; do
		if [ -s "$STATE_FILE" ] && in_zone; then
			"$SCRIPT" show
		fi
		sleep 0.09
	done
}

# Solo corre en modo daemon; si se hace "source" (p.ej. para testear in_zone)
# se cargan las funciones sin entrar al loop.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	loop
fi