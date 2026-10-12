#!/usr/bin/env bash
#
# apply-theme.sh — aplica la paleta ya generada por matugen a las apps en vivo.
#
# Se asume que matugen YA corrió y escribió los archivos de salida (lo hace
# retheme.sh). Este script solo "empuja" los colores a lo que ya está corriendo:
#   - kitty        -> SIGUSR1 (recarga config, incluye current-theme.conf)
#   - fish         -> SIGUSR1 a consolas interactivas (recargan zzz_custom_theme.fish)
#   - waybar       -> restart
#   - swaync       -> recarga del CSS (swaync-client --reload-css)
#   - nwg-bar      -> restart si está abierto
#   - nwg-dock     -> restart (GTK3 no recarga style.css en caliente)
#   - hyprland     -> bordes y fondo (hyprctl keyword), leídos de colors.lua
set -u

# --- kitty -------------------------------------------------------------------
if command -v pkill &>/dev/null && pgrep -x kitty >/dev/null; then
	pkill -USR1 -x kitty
fi

# --- fish --------------------------------------------------------------------
# Solo se avisa a shells con tty (interactivos): un SIGUSR1 a un fish no
# interactivo lo mataría. El handler está en ~/.config/fish/config.fish.
for pid in $(pgrep -x fish); do
	tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
	case "$tty" in
		"" | "?") continue ;;
	esac
	kill -USR1 "$pid" 2>/dev/null
done

# --- waybar ------------------------------------------------------------------
if pgrep -x waybar >/dev/null; then
	pkill -x waybar
	sleep 0.3
fi
waybar & disown

# --- swaync ------------------------------------------------------------------
if pgrep -x swaync >/dev/null; then
	swaync-client --reload-css
else
	swaync & disown
fi

# --- nwg-bar ------------------------------------------------------------------
if pgrep -x nwg-bar >/dev/null; then
	pkill -x nwg-bar
	sleep 0.2
	nwg-bar & disown
fi

# --- nwg-dock ----------------------------------------------------------------
# GTK3 no recarga style.css en caliente, así que se reinicia. Con -d una
# instancia "residente" no se mata reejecutando el comando: hay que pkill.
# OJO: -f con anclaje "^" y no -x, porque "nwg-dock-hyprland" supera los 15
# caracteres de /proc/comm y `pgrep -x` nunca matchearía. El anclaje evita que
# un `bash -c` que mencione el nombre en su cmdline se mate a sí mismo.
if pgrep -f '^nwg-dock-hyprland' >/dev/null; then
	pkill -f '^nwg-dock-hyprland'
	sleep 0.3
	nwg-dock-hyprland -d -i 38 -w 10 & disown
fi

# --- conky --------------------------------------------------------------------
if command -v conky &>/dev/null; then
	if pgrep -x conky >/dev/null; then
		pkill -x conky
		sleep 0.3
	fi
	conky & disown
fi

# --- hyprland (bordes y fondo) ------------------------------------------------
# Lee los colores del colors.lua recién generado y los aplica al instante con
# hyprctl keyword. En el próximo login se cargan solos desde colors.lua.
COLORS_LUA="$HOME/.config/hypr/hyprland/colors.lua"
if command -v hyprctl &>/dev/null && [ -f "$COLORS_LUA" ]; then
	ACTIVE_BORDER=$(sed -n 's/.*active_border   = "rgba(\([0-9A-Fa-f]\{8\}\)).*/\1/p' "$COLORS_LUA")
	INACTIVE_BORDER=$(sed -n 's/.*inactive_border = "rgba(\([0-9A-Fa-f]\{8\}\)).*/\1/p' "$COLORS_LUA")
	BACKGROUND=$(sed -n 's/.*background_color = "rgba(\([0-9A-Fa-f]\{8\}\)).*/\1/p' "$COLORS_LUA")

	if [ -n "$ACTIVE_BORDER" ]; then
		hyprctl keyword general:col.active_border "rgba($ACTIVE_BORDER)" >/dev/null
	fi
	if [ -n "$INACTIVE_BORDER" ]; then
		hyprctl keyword general:col.inactive_border "rgba($INACTIVE_BORDER)" >/dev/null
	fi
	if [ -n "$BACKGROUND" ]; then
		hyprctl keyword misc:background_color "rgba($BACKGROUND)" >/dev/null
	fi
fi