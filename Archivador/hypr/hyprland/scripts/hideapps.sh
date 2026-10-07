#!/usr/bin/env bash
#
# hideapps.sh — oculta todas las apps en "segundo plano" y las vuelve a
# mostrar. Usa un workspace especial de Hyprland (special:minimized) como
# bandeja: mover ahí una ventana la esconde del escritorio (como si quedara
# minimizada en el fondo) y volver a traerla la "despliega".
#
# Uso:
#   hideapps.sh            -> toggle (ocultar si están visibles / mostrar si ocultas)
#   hideapps.sh hide       -> ocultar TODAS las ventanas visibles
#   hideapps.sh show       -> mostrar (restaurar) todas las ocultas
#   hideapps.sh status     -> salida JSON para el módulo de waybar
#
# Requiere: hyprctl, jq

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hideapps"
STATE_FILE="$STATE_DIR/state"
SPECIAL="special:minimized"

notify() { notify-send "$@" -a "HideApps" 2>/dev/null || true; }

hide() {
	mkdir -p "$STATE_DIR"
	# Ventanas "normales" (workspace id >= 1, mapeadas, con pid) que no sean el propio bar.
	mapfile -t wins < <(
		hyprctl -j clients 2>/dev/null |
			jq -r '.[] | select(.mapped == true and .pid != null and .workspace.id >= 1) |
			       "\(.address)\t\(.workspace.id)"'
	)
	# Avoid hiding twice: si ya había un estado, lo descartamos para recalcular.
	if [ ${#wins[@]} -eq 0 ]; then
		notify "No hay apps para ocultar"
		return 0
	fi

	# Mover primero y escribir el estado al final: así el daemon de hover no ve
	# un estado a medias mientras se ocultan (evita carreras / restaurar antes de tiempo).
	local tmp_state="$STATE_FILE.tmp"
	: > "$tmp_state"
	# Hyprland 0.56 (lua): los dispatches van como expresiones lua
	for w in "${wins[@]}"; do
		local addr ws
		addr="${w%%$'\t'*}"
		ws="${w#*$'\t'}"
		printf '%s\t%s\n' "$addr" "$ws" >> "$tmp_state"
		hyprctl dispatch "hl.dsp.window.move({workspace='$SPECIAL',window='address:$addr'})" >/dev/null 2>&1
	done
	mv "$tmp_state" "$STATE_FILE"
	notify "Apps en segundo plano" "Ocultadas ${#wins[@]} app(s). Pasá el cursor por el icono para mostrarlas."
}

show() {
	if [ ! -s "$STATE_FILE" ]; then
		return 0
	fi
	local last=""
	while IFS=$'\t' read -r addr wsid; do
		[ -n "$addr" ] || continue
		hyprctl dispatch "hl.dsp.window.move({workspace=$wsid,window='address:$addr'})" >/dev/null 2>&1
		last="$addr"
	done < "$STATE_FILE"
	rm -f "$STATE_FILE"
	if [ -n "$last" ]; then
		hyprctl dispatch "hl.dsp.focus({window='address:$last'})" >/dev/null 2>&1 || true
	fi
}

status() {
	if [ -s "$STATE_FILE" ]; then
		count=$(wc -l < "$STATE_FILE")
		# JSON de waybar: clase "hidden" cambia el color del icono
		printf '{"text":"","class":"hidden","tooltip":"%s app(s) ocultas en segundo plano. Pasa el cursor para mostrarlas o haz clic para restaurarlas."}\n' "$count"
	else
		printf '{"text":"","class":"","tooltip":"Ocultar apps en segundo plano. Clic: ocultar todas."}\n'
	fi
}

case "${1:-toggle}" in
	toggle)
		if [ -s "$STATE_FILE" ]; then show; else hide; fi
		;;
	hide)   hide   ;;
	show)   show   ;;
	status) status ;;
	*)
		echo "Uso: hideapps.sh [toggle|hide|show|status]" >&2
		exit 1
		;;
esac