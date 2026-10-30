#!/usr/bin/env bash
#
# bgapps.sh — gestiona las apps "en segundo plano" para el módulo de waybar.
#
# Una app en segundo plano vive en un workspace especial (special:minimized)
# guardando de dónde vino. El módulo de waybar muestra un SOLO icono (leader)
# con el recuento; al pasar el cursor (group + drawer) se despliegan los slots
# con cada app individual, y un clic la restaura al workspace original.
#
# Uso:
#   bgapps.sh hide           -> manda la ventana activa a segundo plano
#   bgapps.sh restore N      -> restaura (vuelve a traer) la app de la posición N
#   bgapps.sh restore-all    -> restaura todas
#   bgapps.sh status         -> JSON para el leader del drawer (recuento)
#   bgapps.sh slot N         -> JSON para el slot N (icono de la app) o vacío
#   bgapps.sh hide-all       -> manda todas las ventanas visibles a segundo plano
#
# Requiere: hyprctl, jq

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bgapps"
STATE_FILE="$STATE_DIR/state.json"

notify() { notify-send "$@" -a "BGApps" 2>/dev/null || true; }

# icono nerdfont por clase
icon_for() {
	case "${1,,}" in
		firefox) echo "" ;;
		librewolf) echo "" ;;
		chromium|google-chrome|brave-browser) echo "" ;;
		code|code-oss) echo "󰨞" ;;
		discord) echo "" ;;
		spotify) echo "" ;;
		telegramdesktop|telegram) echo "" ;;
		kitty|alacritty|wezterm|foot|ghostty) echo "" ;;
		virt-manager) echo "󰪵" ;;
		blender) echo "󰂫" ;;
		gimp) echo "󰂥" ;;
		inkscape) echo "" ;;
		dolphin|nautilus|thunar) echo "󰉋" ;;
		steam) echo "" ;;
		obsidian) echo "󰽗" ;;
		zathura|okular|evince) echo "󰈇" ;;
		*aud*) echo "󰓃" ;;
		*) echo "󰘔" ;;
	esac
}

get_state() {
	[ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "[]"
}

set_state() {
	mkdir -p "$STATE_DIR"
	printf '%s\n' "$1" > "$STATE_FILE"
}

# Dirección de la ventana realmete minimizada de la posición N (1-based); vacío si no hay
addr_at() {
	local n="$1" addr
	addr=$(printf '%s' "$(get_state)" | jq -r --argjson i "$((n-1))" '.[$i].address // empty')
	[ -z "$addr" ] || [ "$addr" = "null" ] && return 1
	printf '%s' "$addr"
}

is_minimized() { # is_minimized <address>
	local cur
	cur=$(hyprctl -j clients 2>/dev/null | jq -r --arg a "$1" '.[] | select(.address==$a) | .workspace.name // empty')
	[ "$cur" = "special:minimized" ]
}

hide() {
	mkdir -p "$STATE_DIR"
	local addr ws class title
	addr=$(hyprctl -j activewindow 2>/dev/null | jq -r '.address // empty')
	[ -n "$addr" ] && [ "$addr" != "null" ] || { notify "No hay ventana activa"; return 1; }
	is_minimized "$addr" && return 0
	ws=$(hyprctl -j activewindow 2>/dev/null | jq -r '.workspace.id')
	class=$(hyprctl -j activewindow 2>/dev/null | jq -r '.class')
	title=$(hyprctl -j activewindow 2>/dev/null | jq -r '.title')
	local st
	st=$(get_state)
	st=$(printf '%s' "$st" | jq -c --arg a "$addr" --arg w "$ws" --arg c "$class" --arg t "$title" \
		'. + [{"address":$a,"ws":($w|tonumber),"class":$c,"title":$t}]')
	set_state "$st"
	hyprctl dispatch "hl.dsp.window.move({workspace='special:minimized',window='address:$addr'})" >/dev/null 2>&1
	notify "App a segundo plano" "$class"
}

hide_all() {
	mkdir -p "$STATE_DIR"
	mapfile -t wins < <(
		hyprctl -j clients 2>/dev/null |
			jq -r '.[] | select(.mapped == true and .pid != null and .workspace.id >= 1 and .workspace.name != "special:minimized") |
			       [.address, (.workspace.id|tostring), .class, .title] | @tsv'
	)
	[ ${#wins[@]} -gt 0 ] || { notify "No hay apps para ocultar"; return 0; }
	local st
	st=$(get_state)
	for w in "${wins[@]}"; do
		local addr ws class title
		IFS=$'\t' read -r addr ws class title <<< "$w"
		st=$(printf '%s' "$st" | jq -c --arg a "$addr" --arg w "$ws" --arg c "$class" --arg t "$title" \
			'. + [{"address":$a,"ws":($w|tonumber),"class":$c,"title":$t}]')
	done
	set_state "$st"
	for w in "${wins[@]}"; do
		local addr
		IFS=$'\t' read -r addr _ <<< "$w"
		hyprctl dispatch "hl.dsp.window.move({workspace='special:minimized',window='address:$addr'})" >/dev/null 2>&1
	done
	notify "Apps en segundo plano" "Ocultadas ${#wins[@]} app(s)"
}

restore() {
	local n="${1:-1}" addr ws
	addr=$(addr_at "$n") || return 1
	ws=$(printf '%s' "$(get_state)" | jq -r --arg a "$addr" '.[] | select(.address==$a) | .ws')
	hyprctl dispatch "hl.dsp.window.move({workspace=$ws,window='address:$addr'})" >/dev/null 2>&1
	hyprctl dispatch "hl.dsp.focus({window='address:$addr'})" >/dev/null 2>&1 || true
	local st
	st=$(printf '%s' "$(get_state)" | jq -c --arg a "$addr" '[.[] | select(.address != $a)]')
	set_state "$st"
}

restore_all() {
	local st
	st=$(get_state)
	[ "$st" = "[]" ] && return 0
	# restaurar en orden inverso
	while IFS=$'\t' read -r addr ws _; do
		[ -n "$addr" ] || continue
		hyprctl dispatch "hl.dsp.window.move({workspace=$ws,window='address:$addr'})" >/dev/null 2>&1
	done < <(printf '%s' "$st" | jq -r 'reverse | .[] | [.address, (.ws|tostring)] | @tsv')
	rm -f "$STATE_FILE"
}

count_minimized() {
	printf '%s' "$(get_state)" | jq -r '.[].address' | while read -r a; do
		[ -z "$a" ] || [ "$a" = "null" ] && continue
		is_minimized "$a" && printf 'x'
	done | wc -c
}

status() {
	local valid
	valid=$(count_minimized)
	if [ "$valid" -gt 0 ]; then
		printf '{"text":"󰊪 %s","class":"hidden","tooltip":"%s app(s) en segundo plano. Pasa el cursor para verlas."}\n' "$valid" "$valid"
	else
		printf '{"text":"󰊪","class":"none","tooltip":"Ninguna app en segundo plano. Clic: mandar la ventana activa al fondo."}\n'
	fi
}

slot() {
	local n="${1:-1}" addr line
	addr=$(addr_at "$n") || { printf '{"text":"","class":"empty"}\n'; return; }
	is_minimized "$addr" || { printf '{"text":"","class":"empty"}\n'; return; }
	line=$(printf '%s' "$(get_state)" | jq -r --arg a "$addr" '.[] | select(.address==$a) | {class,title} | @json')
	local class title short
	class=$(printf '%s' "$line" | jq -r '.class')
	title=$(printf '%s' "$line" | jq -r '.title')
	short="$title"
	[ ${#short} -gt 40 ] && short="${short:0:40}…"
	printf '{"text":"%s","class":"app","tooltip":"%s\\nClic: restaurar"}\n' "$(icon_for "$class")" "$short"
}

case "${1:-status}" in
	hide)      hide ;;
	hide-all)  hide_all ;;
	restore)   restore "${2:-1}" ;;
	restore-all) restore_all ;;
	slot)      slot "${2:-1}" ;;
	status)    status ;;
	*)
		echo "Uso: bgapps.sh [hide|hide-all|restore N|restore-all|slot N|status]" >&2
		exit 1
		;;
esac