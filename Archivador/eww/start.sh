#!/usr/bin/env bash
# Arranque de eww: daemon, ventanas y puente de cava.
# Este script es la ÚNICA fuente de verdad del arranque. Si lanzás `eww daemon`
# y `eww open ...` a mano desde hyprland, el puente de cava no se levanta nunca
# y el visualizador queda vacío.
LOG="$HOME/.cache/eww-start.log"
{
	echo "=== eww start.sh $(date)"

	# 1) Puente de cava ANTES que eww, para que /tmp/eww-cava.txt ya exista
	#    cuando eww monte el widget y la etiqueta no arranque vacía.
	if ! pgrep -f "cava-watchdog.sh" >/dev/null; then
		bash "$HOME/.config/eww/cava-watchdog.sh" >/dev/null 2>&1 &
		echo "watchdog de cava lanzado"
	fi

	# 2) Esperar a que hyprland acepte comandos.
	for _ in $(seq 1 60); do
		hyprctl monitors >/dev/null 2>&1 && break
		sleep 0.5
	done
	echo "hypr ready: $(date)"

	# 3) Daemon de eww.
	if ! pgrep -x eww >/dev/null; then
		eww daemon >/dev/null 2>&1 &
		echo "daemon lanzado"
	fi

	for _ in $(seq 1 40); do
		eww ping >/dev/null 2>&1 && break
		sleep 0.5
	done
	echo "ping listo: $(date)"

	eww open music
	eww open weather
	eww open clock
} >>"$LOG" 2>&1