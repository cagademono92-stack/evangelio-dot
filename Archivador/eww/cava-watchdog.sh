#!/usr/bin/env bash
# Vigila que /tmp/eww-cava.txt esté fresco y reinicia el bridge de cava
# si se queda sin actualizarse (eww dejaría de moverse).
while true; do
	bash "$HOME/.config/eww/cava-eww.sh" &
	BGPID=$!
	# Espera a que el bridge empiece a escribir
	sleep 3
	# Monitorea mientras el archivo se actualice
	while true; do
		sleep 2
		now=$(date +%s)
		mt=$(stat -c %Y /tmp/eww-cava.txt 2>/dev/null || echo 0)
		if [ $((now - mt)) -gt 3 ]; then
			kill "$BGPID" 2>/dev/null
			pkill -f "cava -p" 2>/dev/null
			break
		fi
	done
	sleep 1
done
