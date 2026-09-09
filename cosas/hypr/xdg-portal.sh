#!/bin/bash
sleep 1
# Matar cualquier proceso que haya intentado arrancar mal
killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal-wlr
killall -e xdg-desktop-portal-gnome
killall xdg-desktop-portal

# Iniciar el portal de Hyprland
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2

# Iniciar el portal principal
/usr/lib/xdg-desktop-portal &
