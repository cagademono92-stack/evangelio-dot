#!/usr/bin/env bash
#
# CavaAutoShow.sh
#
# Corre en segundo plano y vigila si hay audio sonando en el sistema
# (cualquier sink-input en estado RUNNING). Cuando detecta sonido, abre una
# terminal flotante corriendo cava. Cuando el audio se detiene, la cierra.
#
# Requiere: pactl (pipewire-pulse o pulseaudio), jq, hyprctl, kitty, cava
#
# Instalación rápida:
#   sudo pacman -S cava jq kitty
#
# Uso manual (para probar):
#   chmod +x CavaAutoShow.sh
#   ./CavaAutoShow.sh
#
# Para que arranque solo con la sesión, agregá esto a tu lua/startup_apps.lua
# (dentro de hl.on("hyprland.start", function() ... end)):
#   hl.exec_cmd(HOME .. "/.config/hypr/scripts/CavaAutoShow.sh")

TERMINAL="kitty"
WIN_CLASS="cava-float"
CHECK_INTERVAL=1 # segundos entre chequeos

is_audio_playing() {
	# true si hay al menos un sink-input en estado RUNNING (algo sonando de verdad,
	# no solo abierto/pausado)
	pactl list sink-inputs 2>/dev/null | grep -q "State: RUNNING"
}

is_cava_window_open() {
	hyprctl clients -j 2>/dev/null | jq -e --arg class "$WIN_CLASS" \
		'.[] | select(.class == $class)' >/dev/null 2>&1
}

open_cava_window() {
	"$TERMINAL" --class="$WIN_CLASS" -e cava &
	disown
}

close_cava_window() {
	hyprctl dispatch closewindow "class:^(${WIN_CLASS})$" >/dev/null 2>&1
}

# Evita instancias duplicadas del propio script
LOCKFILE="/tmp/CavaAutoShow.lock"
if [ -e "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
	echo "CavaAutoShow.sh ya está corriendo (PID $(cat "$LOCKFILE"))."
	exit 1
fi
echo $$ >"$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

while true; do
	if is_audio_playing; then
		is_cava_window_open || open_cava_window
	else
		is_cava_window_open && close_cava_window
	fi
	sleep "$CHECK_INTERVAL"
done
