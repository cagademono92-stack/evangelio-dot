#!/usr/bin/env bash
# gpu-temp.sh — Temperatura de la GPU dedicada (AMD/NVIDIA) para waybar.
# Uso: gpu-temp.sh [--vertical]
# Si no hay GPU dedicada con sensor expuesto, devuelve el módulo oculto
# (texto vacío + class "hidden" para que el CSS lo esconda).

if [ "$1" = "--vertical" ]; then
	VERTICAL=1
else
	VERTICAL=0
fi

temp=""
gpu_name=""
gpu_label=""

for hw in /sys/class/hwmon/hwmon*; do
	[ -d "$hw" ] || continue
	name="$(cat "$hw/name" 2>/dev/null)"
	case "$name" in
		amdgpu)
			for f in "$hw"/temp*_input; do
				[ -f "$f" ] || continue
				label="$(cat "${f%_input}_label" 2>/dev/null)"
				if [[ "$label" =~ edge|junction|gpu|hot ]]; then
					temp="$(cat "$f")"
					gpu_label="${label^}" # "Edge" -> "Edge"
					break
				fi
			done
			# Si AMD no expone labels claros usa la primera lectura disponible.
			if [ -z "$temp" ]; then
				first="$(ls "$hw"/temp*_input 2>/dev/null | head -n1)"
				if [ -n "$first" ]; then
					temp="$(cat "$first")"
					gpu_label="GPU"
				fi
			fi
			[ -n "$temp" ] && gpu_name="AMD"
			;;
		nvidia)
			if [ -f "$hw/temp1_input" ]; then
				temp="$(cat "$hw/temp1_input")"
				gpu_name="NVIDIA"
				gpu_label="GPU"
			fi
			;;
	esac
	[ -n "$temp" ] && break
done

if [ -n "$temp" ]; then
	c=$(( temp / 1000 ))
	if [ "$VERTICAL" -eq 1 ]; then
		printf '{"text":"󰢮","alt":"gpu","tooltip":"%s %s: %d°C","class":"gpu"}' "$gpu_name" "$gpu_label" "$c"
	else
		printf '{"text":"%3d°C 󰢮","alt":"gpu","tooltip":"%s %s: %d°C","class":"gpu"}' "$c" "$gpu_name" "$gpu_label" "$c"
	fi
else
	printf '{"text":"","alt":"nogpu","tooltip":"","class":"hidden"}'
fi