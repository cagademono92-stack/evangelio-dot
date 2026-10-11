#!/usr/bin/env bash
#
# install.sh — instalación 100% automática de evangelio-dot.
#
# Uso:
#   1) Descomprimí Archivador.zip (o cloná el repo)
#   2) chmod +x install.sh && ./install.sh
#
# El script NO pregunta nada: instala dependencias, hace backup de tu
# ~/.config actual y copia la configuración nueva. Al final te dice qué
# pasos manuales quedan (wallpaper, etc.).
#
# Soporte: Arch Linux / derivadas (CachyOS, Omarchy, EndeavourOS...)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

echo "=== 1/6: Verificando sistema ==="
if ! command -v pacman &>/dev/null; then
	echo "ERROR: no se encontró pacman. Este script es para Arch/derivadas." >&2
	exit 1
fi

# --- Root para pacman ---
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	if command -v sudo &>/dev/null; then
		SUDO="sudo"
	else
		echo "ERROR: necesitás sudo o root para instalar paquetes." >&2
		exit 1
	fi
fi

echo ""
echo "=== 2/6: Verificando yay ==="
if ! command -v yay &>/dev/null; then
	echo "yay no está instalado. Instalando desde AUR..."
	$SUDO pacman -S --needed --noconfirm git base-devel
	tmpdir=$(mktemp -d)
	git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
	(cd "$tmpdir/yay" && makepkg -si --noconfirm)
	rm -rf "$tmpdir"
else
	echo "yay ya está instalado."
fi

echo ""
echo "=== 3/6: Instalando dependencias (automático) ==="

# Paquetes oficiales (pacman)
OFFICIAL_PKGS=(
	# Componentes principales del escritorio
	waybar
	rofi
	swaync
	fish
	kitty
	# Wallpaper + theming dinámico
	hyprpaper
	# Resto de utilidades que usan tus keybinds y scripts
	hyprlock
	hypridle
	nwg-bar
	nwg-displays
	wf-recorder
	wvkbd
	hyprpicker
	hyprshot
	cliphist
	playerctl
	brightnessctl
	pavucontrol
	network-manager-applet
	cava
	grim
	slurp
	jq
	fuzzel
	conky
	eww
	# Fuentes usadas por waybar/rofi/kitty/eww/conky
	ttf-jetbrains-mono-nerd
	noto-fonts-emoji
	wl-clipboard
	wtype
	tesseract
	bc
	xdg-user-dirs
	easyeffects
	gnome-keyring
	gpu-screen-recorder
	xdg-desktop-portal
	xdg-desktop-portal-hyprland
	hyprpolkitagent
)

# Paquetes AUR (yay)
AUR_PKGS=(
	matugen
	waypaper
	gpu-screen-recorder
	hyprpolkitagent
	ttf-jetbrains-mono-nerd
)

echo "Instalando ${#OFFICIAL_PKGS[@]} paquetes oficiales con pacman..."
$SUDO pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

echo "Instalando ${#AUR_PKGS[@]} paquetes AUR con yay..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

echo ""
echo "=== 4/6: Detectando carpetas de config junto a este script ==="
FOLDERS=()
for entry in "$SCRIPT_DIR"/*/; do
	[ -d "$entry" ] || continue
	FOLDERS+=("$(basename "$entry")")
done

if [ ${#FOLDERS[@]} -eq 0 ]; then
	echo "ERROR: no encontré ninguna carpeta al lado de install.sh." >&2
	exit 1
fi

echo "Carpetas encontradas: ${FOLDERS[*]}"

echo ""
echo "=== 5/6: Backup de tu ~/.config actual ==="
mkdir -p "$BACKUP_DIR"
for dir in "${FOLDERS[@]}"; do
	if [ -d "$CONFIG_DIR/$dir" ]; then
		echo "Backup: $CONFIG_DIR/$dir -> $BACKUP_DIR/$dir"
		mv "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
	fi
done
echo "Backup completo en: $BACKUP_DIR"

echo ""
echo "=== 6/6: Copiando la config nueva a ~/.config ==="
for dir in "${FOLDERS[@]}"; do
	mkdir -p "$CONFIG_DIR/$dir"
	cp -r "$SCRIPT_DIR/$dir/." "$CONFIG_DIR/$dir/"
	echo "Copiado: $dir/ -> $CONFIG_DIR/$dir/"
done

# --- Arreglos post-copia (automáticos) ---

# waypaper/config.ini: rutas absolutas con usuario viejo -> $HOME real
if [ -f "$CONFIG_DIR/waypaper/config.ini" ]; then
	sed -i "s|/home/[^/]*/\.config|$HOME/.config|g; s|/home/[^/]*|$HOME|g" "$CONFIG_DIR/waypaper/config.ini"
	echo "Ajustado: rutas de usuario en waypaper/config.ini -> $HOME"
fi

# fish/config.fish: puede traer rutas viejas tipo /home/receck/...
if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
	sed -i "s|/home/[^/]*/|$HOME/|g" "$CONFIG_DIR/fish/config.fish"
	echo "Ajustado: rutas de usuario en fish/config.fish -> $HOME"
fi

# hyprpaper.conf / hyprlock: rutas absolutas al usuario original
for f in "$CONFIG_DIR/hypr/hyprpaper.conf" "$CONFIG_DIR/hypr/hyprlock/colors.conf"; do
	if [ -f "$f" ]; then
		sed -i "s|/home/[^/]*|$HOME|g" "$f"
		echo "Ajustado: rutas de usuario en $(basename "$f") -> $HOME"
	fi
done

# Permisos de ejecución para todos los scripts propios
find "$CONFIG_DIR" -maxdepth 5 -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "Permisos de ejecución aplicados a los scripts .sh"

# kitty: el theme lo genera matugen -> current-theme.conf (ya incluido)
# fish: si no es tu shell, el script te lo sugiere al final

echo ""
echo "=========================================="
echo " Instalación completa."
echo " Backup de tu config anterior en:"
echo "   $BACKUP_DIR"
echo ""
echo " Pasos finales:"
echo " 1. Poné tus wallpapers en ~/Pictures/wallpapers/"
echo " 2. Generá los colores por primera vez con:"
echo "      ~/.config/hypr/hyprland/scripts/wallpaper.sh ~/Pictures/wallpapers/TU-IMAGEN.jpg"
echo "    (setea el fondo con hyprpaper y recolorea waybar/rofi/fish/nwg-bar/hyprlock/kitty/swaync/eww/conky)"
echo " 3. hyprctl reload"
echo ""
echo " Si usás fish como shell por defecto y todavía no lo configuraste:"
echo "      chsh -s /usr/bin/fish"
echo "=========================================="
