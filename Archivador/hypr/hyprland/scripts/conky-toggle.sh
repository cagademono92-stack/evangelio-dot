#!/usr/bin/env bash
# conky-toggle.sh — alterna mostrar/ocultar conky y reporta su estado a waybar.
#
#   conky-toggle.sh toggle   -> mata conky si está, lo inicia si no
#   conky-toggle.sh status   -> JSON para waybar ({text, tooltip})
set -u
case "${1:-status}" in
	toggle)
		if pgrep -x conky >/dev/null; then
			pkill -x conky
		else
			conky & disown
		fi
		;;
	status|*)
		if pgrep -x conky >/dev/null; then
			echo '{"text": "󰍹", "tooltip": "Conky visible — clic para ocultar", "class": "on"}'
		else
			echo '{"text": "󰶐", "tooltip": "Conky oculto — clic para mostrar", "class": "off"}'
		fi
		;;
esac
