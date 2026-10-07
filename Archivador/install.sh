#!/usr/bin/env bash
#
# install.sh — instalación automática de yay + dependencias + config.
#
# Uso:
#   1) Descomprimí el Archivador.zip
#   2) Dejá este install.sh en la MISMA carpeta que quedó al descomprimir
#      (o sea: al lado de "hypr", "waybar", "rofi", "swaync", "matugen",
#      "waypaper", "fish", "kitty", "themes")
#   3) chmod +x install.sh && ./install.sh
#
# El script NO tiene hardcodeada la lista de carpetas — copia
# automáticamente TODAS las carpetas que encuentre al lado suyo. Así no
# hay que editarlo cada vez que agregás una carpeta nueva a la config.
#
# Nota sobre ext4: no requiere nada especial por el sistema de archivos —
# cp/mv funcionan igual en ext4 que en cualquier otro FS de Linux.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

echo "=== 1/7: Verificando yay ==="
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
echo "=== 2/7: Instalando dependencias ==="
# Componentes principales del escritorio
CORE_PKGS=(
	waybar
	rofi
	swaync
	fish
	kitty
)
# Wallpaper + theming dinámico (el pipeline matugen)
THEME_PKGS=(
	hyprpaper
	matugen
	waypaper
)
# Resto de utilidades que usan tus keybinds y scripts
EXTRA_PKGS=(
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
)

echo "Principales:  ${CORE_PKGS[*]}"
echo "Theming:      ${THEME_PKGS[*]}"
echo "Utilidades:   ${EXTRA_PKGS[*]}"
read -rp "¿Instalar todo esto con yay? [S/n] " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
	echo "Instalación de paquetes cancelada. Seguimos solo con la copia de config."
else
	yay -S --needed --noconfirm "${CORE_PKGS[@]}" "${THEME_PKGS[@]}" "${EXTRA_PKGS[@]}"
fi

echo ""
echo "=== 3/7: Detectando carpetas de config junto a este script ==="
FOLDERS=()
for entry in "$SCRIPT_DIR"/*/; do
	[ -d "$entry" ] || continue
	FOLDERS+=("$(basename "$entry")")
done

if [ ${#FOLDERS[@]} -eq 0 ]; then
	echo "ERROR: no encontré ninguna carpeta al lado de install.sh."
	echo "¿Lo dejaste junto a hypr/, waybar/, matugen/, etc.?"
	exit 1
fi

echo "Carpetas encontradas: ${FOLDERS[*]}"

echo ""
echo "=== 4/7: Verificando que los templates de matugen estén completos ==="
# matugen falla entero si config.toml apunta a un template que no existe.
MATUGEN_CFG="$SCRIPT_DIR/matugen/config.toml"
if [ -f "$MATUGEN_CFG" ]; then
	missing=0
	while IFS= read -r tpl; do
		tpl_name="$(basename "$tpl")"
		if [ ! -f "$SCRIPT_DIR/matugen/templates/$tpl_name" ]; then
			echo "  FALTA: matugen/templates/$tpl_name (referenciado en config.toml)"
			missing=$((missing + 1))
		else
			echo "  OK: $tpl_name"
		fi
	done < <(grep -oP "input_path\s*=\s*'\K[^']+" "$MATUGEN_CFG")

	if [ "$missing" -gt 0 ]; then
		echo ""
		echo "AVISO: faltan $missing template(s). matugen va a fallar al cambiar el wallpaper."
		read -rp "¿Seguir igual? [s/N] " cont
		[[ "$cont" =~ ^[Ss]$ ]] || exit 1
	fi
else
	echo "  (no encontré matugen/config.toml, salteando esta verificación)"
fi

echo ""
echo "=== 5/7: Verificando que las apps destino de matugen tengan su carpeta ==="
# Complemento del chequeo anterior, pero al revés: si config.toml escribe a
# ~/.config/ALGO/colors.css pero la carpeta "ALGO" no vino en este zip,
# apply-theme.sh va a fallar al reiniciar/recargar esa app. Esto es justo lo
# que pasó con nwg-bar en una vuelta anterior — se armó el template pero se
# olvidó de incluir la carpeta nwg-bar/ en el zip.
if [ -f "$MATUGEN_CFG" ]; then
	while IFS= read -r out; do
		# out es del tipo ~/.config/nwg-bar/colors.css -> nos interesa "nwg-bar"
		rel="${out#\~/.config/}"
		target_dir="${rel%%/*}"
		found=0
		for f in "${FOLDERS[@]}"; do
			[ "$f" = "$target_dir" ] && found=1 && break
		done
		if [ "$found" -eq 0 ]; then
			echo "  AVISO: config.toml escribe a ~/.config/$target_dir/... pero no hay carpeta '$target_dir/' en este zip."
			echo "         Si '$target_dir' ya existe en tu ~/.config de antes, no pasa nada."
			echo "         Si no, agregala al lado de install.sh antes de seguir (o cancelá y la sumás)."
		fi
	done < <(grep -oP "output_path\s*=\s*'\K[^']+" "$MATUGEN_CFG")
fi

echo ""
echo "=== 6/7: Backup de tu ~/.config actual ==="
mkdir -p "$BACKUP_DIR"
for dir in "${FOLDERS[@]}"; do
	if [ -d "$CONFIG_DIR/$dir" ]; then
		echo "Backup: $CONFIG_DIR/$dir -> $BACKUP_DIR/$dir"
		cp -r "$CONFIG_DIR/$dir" "$BACKUP_DIR/$dir"
	fi
done
echo "Backup completo en: $BACKUP_DIR"

echo ""
echo "=== 7/7: Copiando la config nueva a ~/.config ==="
for dir in "${FOLDERS[@]}"; do
	mkdir -p "$CONFIG_DIR/$dir"
	cp -r "$SCRIPT_DIR/$dir/." "$CONFIG_DIR/$dir/"
	echo "Copiado: $dir/ -> $CONFIG_DIR/$dir/"
done

# --- Arreglos post-copia ---

# waypaper/config.ini tiene rutas absolutas con un nombre de usuario fijo
# ("/home/receck/..."). Si instalás esto en otra máquina o con otro usuario,
# esas rutas no existen. Las reescribimos al $HOME real de quien instala.
if [ -f "$CONFIG_DIR/waypaper/config.ini" ]; then
	sed -i "s|$HOME/\.config|$HOME/.config|g; s|/home/[^/]*|$HOME|g" "$CONFIG_DIR/waypaper/config.ini"
	echo "Ajustado: rutas de usuario en waypaper/config.ini -> $HOME"
fi

# fish/config.fish puede traer rutas viejas tipo /home/receck/...
if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
	sed -i "s|$HOME/|$HOME/|g" "$CONFIG_DIR/fish/config.fish"
	echo "Ajustado: rutas de usuario en fish/config.fish -> $HOME"
fi

# Rutas absolutas en hyprpaper.conf / hyprlock apuntan al usuario original
for f in "$CONFIG_DIR/hypr/hyprpaper.conf" "$CONFIG_DIR/hypr/hyprlock/colors.conf" "$CONFIG_DIR/rofi/config.rasi"; do
	if [ -f "$f" ]; then
		sed -i "s|/home/[^/]*|$HOME|g" "$f"
		echo "Ajustado: rutas de usuario en $(basename "$f") -> $HOME"
	fi
done

# Permisos de ejecución para todos los scripts propios, estén donde estén
find "$CONFIG_DIR" -maxdepth 5 -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "Permisos de ejecución aplicados a los scripts .sh"

echo ""
echo "=========================================="
echo " Listo. Backup de tu config anterior en:"
echo "   $BACKUP_DIR"
echo ""
echo " Pasos finales:"
echo " 1. Poné tus wallpapers en ~/Pictures/wallpapers/"
echo " 2. Generá los colores por primera vez con:"
echo "      ~/.config/hypr/hyprland/scripts/wallpaper.sh ~/Pictures/wallpapers/TU-IMAGEN.jpg"
echo "    (setea el fondo con hyprpaper y recolorea waybar/rofi/fish/nwg-bar/hyprlock/kitty/swaync)"
echo " 3. hyprctl reload"
echo ""
echo " Si usás fish como shell por defecto y todavía no lo configuraste:"
echo "      chsh -s /usr/bin/fish"
echo "=========================================="
