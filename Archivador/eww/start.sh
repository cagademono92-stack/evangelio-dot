#!/usr/bin/env bash
# Inicia el daemon de eww y abre los widgets una vez listo
pgrep -x eww || eww daemon &
for i in $(seq 1 20); do
	eww ping >/dev/null 2>&1 && break
	sleep 0.5
done
eww open music
eww open weather
eww open clock
