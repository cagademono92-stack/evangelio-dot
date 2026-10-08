#!/usr/bin/env bash
LOG="$HOME/.cache/eww-start.log"
{ 
echo "=== eww start.sh $(date)"
for i in $(seq 1 60); do
	hyprctl monitors >/dev/null 2>&1 && break
	sleep 0.5
done
echo "hypr ready: $(date)"
if ! pgrep -x eww >/dev/null; then
	eww daemon >/dev/null 2>&1 &
	echo "daemon lanzado"
fi
for i in $(seq 1 40); do
	eww ping >/dev/null 2>&1 && break
	sleep 0.5
done
echo "ping listo: $(date)"
eww open music
eww open weather
eww open clock
} >> "$LOG" 2>&1
# watchdog de cava (solo uno)
if ! pgrep -f "cava-watchdog.sh" >/dev/null; then
	bash "$HOME/.config/eww/cava-watchdog.sh" >/dev/null 2>&1 &
fi
