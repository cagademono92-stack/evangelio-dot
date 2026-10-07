#!/usr/bin/env bash
cava -p "$HOME/.config/eww/cava_eww.conf" | while read -r line; do
	out=""
	IFS=';' read -ra vals <<< "$line"
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
	printf '%s' "$out" > /tmp/eww-cava.txt
done
