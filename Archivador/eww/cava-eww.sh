#!/usr/bin/env bash
# Bridge: cava escribe ascii por stdout -> bloques Unicode -> archivo que lee eww.
#
# El archivo se escribe de forma atómica (temp + mv) en vez de con `> archivo`.
# Con `>` el archivo se trunca y se rellena, así que eww podía leer una línea a
# medio escribir y ver la barra parpadear o desaparecer durante un frame.
set -uo pipefail

CONF="$HOME/.config/eww/cava_eww.conf"
OUT="/tmp/eww-cava.txt"
TMP="/tmp/.eww-cava.$$"

cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

cava -p "$CONF" | while IFS=';' read -ra vals; do
	out=""
	for v in "${vals[@]}"; do
		case "$v" in
			0) out+="▁" ;;
			1) out+="▂" ;;
			2) out+="▃" ;;
			3) out+="▄" ;;
			4) out+="▅" ;;
			5) out+="▆" ;;
			6) out+="▇" ;;
			7) out+="█" ;;
		esac
	done
	printf '%s' "$out" > "$TMP" && mv -f "$TMP" "$OUT"
done