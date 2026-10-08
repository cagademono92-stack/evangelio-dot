#!/usr/bin/env bash
# toggle: abre/cierra el panel de ajustes rápidos de eww
case "${1:-toggle}" in
	toggle)
		if eww active-windows | grep -q "qs"; then
			eww close qs
		else
			eww open qs
		fi
		;;
	status)
		echo '{"text": "󰒓", "tooltip": "Ajustes rápidos"}'
		;;
esac
