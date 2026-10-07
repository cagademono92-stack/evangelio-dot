#!/usr/bin/env bash
#
# waybar-watchdog.sh — monitor de salud de waybar
#
# Detecta cuando waybar se congela visualmente (UI no responde pero proceso vivo)
# y lo reinicia automáticamente sin matar el proceso (via señal SIGUSR2).
#
# Uso:
#   waybar-watchdog.sh &        # en segundo plano
#   waybar-watchdog.sh --stop   # detener el monitor
#
# Requiere: waybar, hyprctl, jq

set -u

PIDFILE="/tmp/waybar-watchdog.pid"
LOGFILE="/tmp/waybar-watchdog.log"
CHECK_INTERVAL=2          # segundos entre health checks
FREEZE_THRESHOLD=3        # checks fallidos antes de reiniciar

# --- Stop -------------------------------------------------------------------
if [ "${1:-}" = "--stop" ]; then
	if [ -f "$PIDFILE" ]; then
		kill "$(cat "$PIDFILE")" 2>/dev/null
		rm -f "$PIDFILE"
		notify-send "Waybar Watchdog" "Monitor detenido" -a "Waybar"
	fi
	exit 0
fi

# --- Ya corriendo? ----------------------------------------------------------
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
	echo "Watchdog ya corriendo (PID $(cat "$PIDFILE"))"
	exit 0
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"; exit 0' EXIT INT TERM

# --- Loop principal ---------------------------------------------------------
fail_count=0
while true; do
	sleep "$CHECK_INTERVAL"

	# Verificar que waybar esté corriendo
	if ! pgrep -x waybar >/dev/null; then
		fail_count=0
		continue
	fi

	# Verificar que waybar responda a health checks vía hyprctl
	# Si waybar está congelado, no responde a solicitudes IPC
	if ! timeout 1 hyprctl clients 2>/dev/null | grep -q "waybar"; then
		fail_count=$((fail_count + 1))
	else
		fail_count=0
	fi

	# Si se detecta freeze, reiniciar waybar sin matar el proceso
	if [ "$fail_count" -ge "$FREEZE_THRESHOLD" ]; then
		echo "$(date): waybar congelado detectado, reiniciando UI..." >> "$LOGFILE"

		# Reenviar señal a waybar para que recargue la UI sin matar el proceso
		# SIGUSR2 es la señal estándar de waybar para reload suave
		pkill -USR2 -x waybar 2>/dev/null

		# Si no responde, forzar reload via hyprctl
		sleep 0.5
		if pgrep -x waybar >/dev/null; then
			hyprctl dispatch exec "waybar -r" 2>/dev/null || true
		fi

		notify-send "Waybar" "UI congelada detectada, reiniciando..." -a "Watchdog"
		fail_count=0
	fi
done
