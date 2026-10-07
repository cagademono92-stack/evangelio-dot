#!/usr/bin/env bash
#
# HeadlessDisplay-Off.sh — saca el monitor virtual que creó
# HeadlessDisplay-On.sh. Usa el archivo de estado, no adivina el nombre.

STATE_FILE="/tmp/hypr-headless-display.name"

if [ ! -f "$STATE_FILE" ]; then
	notify-send "Segundo monitor" "No hay ningún headless activo (o no lo creaste con HeadlessDisplay-On.sh)" -a "Hyprland"
	exit 0
fi

HEADLESS_NAME=$(cat "$STATE_FILE")
hyprctl output remove "$HEADLESS_NAME"
rm -f "$STATE_FILE"

notify-send "Segundo monitor" "Sacado: $HEADLESS_NAME" -a "Hyprland"
