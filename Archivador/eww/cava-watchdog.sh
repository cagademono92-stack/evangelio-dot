#!/usr/bin/env bash
# Mantiene vivo el bridge de cava (cava-eww.sh).
#
# Antes este script usaba `pkill -f "cava -p"` para limpiar, que también mataba
# el cava flotante que abre CavaAutoShow.sh en una kitty, y `kill $BGPID` que
# solo mataba el bash dejando procesos cava huérfanos acumulados. Ahora cada
# bridge corre en su propio process group (setsid) y se mata el grupo entero,
# así que nunca tocamos otras instancias de cava.
set -uo pipefail

OUT="/tmp/eww-cava.txt"
BRIDGE="$HOME/.config/eww/cava-eww.sh"
MAX_STALE=3 # segundos sin actualizar el archivo antes de reiniciar

BRIDGE_PID=""

cleanup() {
	[ -n "$BRIDGE_PID" ] && kill -- "-$BRIDGE_PID" 2>/dev/null
	wait 2>/dev/null
	exit 0
}
trap cleanup INT TERM

while true; do
	# setsid -> el bridge y su cava hijo comparten pgid == su propio pid,
	# así que `kill -- -PID` los mata a todos y solo a ellos.
	setsid bash "$BRIDGE" &
	BRIDGE_PID=$!

	# Espera a que el bridge produzca la primera línea antes de mirar staleness.
	for _ in $(seq 1 20); do
		[ -s "$OUT" ] && break
		sleep 0.5
	done

	# Vigila mientras el bridge siga vivo y el archivo se mantenga fresco.
	while kill -0 "$BRIDGE_PID" 2>/dev/null; do
		sleep 1
		now=$(date +%s)
		mt=$(stat -c %Y "$OUT" 2>/dev/null || echo 0)
		# mt == 0 -> el archivo no existe: cava no arrancó, hay que reintentar.
		# si no -> el bridge quedó congelado.
		if [ "$mt" -eq 0 ] || [ $((now - mt)) -gt "$MAX_STALE" ]; then
			break
		fi
	done

	kill -- "-$BRIDGE_PID" 2>/dev/null
	wait "$BRIDGE_PID" 2>/dev/null
	BRIDGE_PID=""
	sleep 1
done