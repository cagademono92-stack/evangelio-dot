#!/usr/bin/env bash
#
# install.sh — instalación automática de yay + dependencias + config.
#
# Uso:
#   1) Descomprimí cosas.zip
#   2) Dejá este install.sh en la MISMA carpeta que quedó al descomprimir
#      (o sea: al lado de la carpeta "hypr", "waybar", "rofi", "swaync")
#   3) chmod +x install.sh && ./install.sh
#
# Nota sobre ext4: esto no requiere nada especial por el sistema de
# archivos — cp/mv funcionan igual en ext4 que en cualquier otro FS de
# Linux, así que el script no hace ninguna distinción ahí.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

echo "=== 1/4: Verificando yay ==="
if ! command -v yay &>/dev/null; then
	echo "yay no está instalado. Instalando desde AUR..."
	sudo pacman -S --needed --noconfirm git base-devel
	tmpdir=$(mktemp -d)
	git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
	(cd "$tmpdir/yay" && makepkg -si --noconfirm)
	rm -rf "$tmpdir"
else
	echo "yay ya está instalado, salteando."
fi

echo ""
echo "=== 2/4: Instalando dependencias ==="
# Lo que pediste explícitamente:
CORE_PKGS=(waybar rofi swaync)
# Lo que tu config ya usa y necesita para no romperse (hyprpaper/matugen para
# el theming dinámico, y el resto de binds que armamos en keybinds.lua):
EXTRA_PKGS=(
	hyprpaper
	matugen
	waypaper
	nwg-bar
	wf-recorder
	wvkbd
	hyprpicker
	hyprshot
	cliphist
	playerctl
	brightnessctl
	grim
	slurp
	jq
	fuzzel
)

echo "Paquetes principales: ${CORE_PKGS[*]}"
echo "Dependencias extra:   ${EXTRA_PKGS[*]}"
read -rp "¿Instalar todo esto con yay? [S/n] " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
	echo "Instalación de paquetes cancelada. Seguimos solo con la copia de config."
else
	yay -S --needed --noconfirm "${CORE_PKGS[@]}" "${EXTRA_PKGS[@]}"
fi

echo ""
echo "=== 3/4: Backup de tu ~/.config actual ==="
mkdir -p "$BACKUP_DIR"
for dir in hypr waybar rofi swaync; do
	if [ -d "$CONFIG_DIR/$dir" ]; then
		echo "Backup: $CONFIG_DIR/$dir -> $BACKUP_DIR/$dir"
		cp -r "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
	fi
done
echo "Backup completo en: $BACKUP_DIR"

echo ""
echo "=== 4/4: Copiando la config nueva a ~/.config ==="
for dir in hypr waybar rofi swaync; do
	if [ -d "$SCRIPT_DIR/$dir" ]; then
		mkdir -p "$CONFIG_DIR/$dir"
		cp -r "$SCRIPT_DIR/$dir/." "$CONFIG_DIR/$dir/"
		echo "Copiado: $dir/ -> $CONFIG_DIR/$dir/"
	else
		echo "AVISO: no encontré la carpeta '$dir' al lado de este script, salteando."
	fi
done

# El KooL_style-5.rasi suelto va directo a la carpeta de rofi
if [ -f "$SCRIPT_DIR/KooL_style-5.rasi" ]; then
	mkdir -p "$CONFIG_DIR/rofi"
	cp "$SCRIPT_DIR/KooL_style-5.rasi" "$CONFIG_DIR/rofi/KooL_style-5.rasi"
	echo "Copiado: KooL_style-5.rasi -> $CONFIG_DIR/rofi/"
fi

# Permisos de ejecución para los scripts propios
find "$CONFIG_DIR/hypr" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "=========================================="
echo " Listo. Backup de tu config anterior en:"
echo "   $BACKUP_DIR"
echo ""
echo " Antes de recargar Hyprland:"
echo " 1. Editá ~/.config/hypr/hyprpaper.conf y poné la ruta real de tu"
echo "    wallpaper (ahora mismo apunta a un archivo 'default.png' de ejemplo)."
echo " 2. Corré: matugen image ~/Pictures/wallpapers/tu-wallpaper.png"
echo "    para generar los colores por primera vez."
echo " 3. hyprctl reload"
echo "=========================================="
