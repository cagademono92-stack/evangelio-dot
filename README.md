# evangelion-dot

Dotfiles de mi escritorio Hyprland, basados en [ii](https://github.com/end-4/dots-hyprland) (retroboxed / Evangelion edition).

Incluye:
- **Hyprland** con config en Lua, keybinds, reglas y scripts
- **Waybar** arriba con módulos customizados
- **Rofi** como lanzador, **swaync** como centro de notificaciones
- **matugen** para recolorear everything (kitty, rofi, waybar, fish, eww…) cada vez que cambias de wallpaper con waypaper
- **kitty + fish + starship** como terminal
- **conky** widget de sistema (red, disco, swap, uptime, kernel)
- **eww**: widget de música con botones + cava + reloj centrado estilo end4
- **hyprlock/hypridle** para bloqueo, **hyprpaper** para fondo

## Instalación

Requisitos: **Arch Linux** (o derivada estilo CachyOS/Omarchy) con `yay`. El propio script instala `yay` si no lo tienes.

```bash
git clone https://github.com/cagademono92-stack/evangelio-dot.git
cd evangelio-dot
chmod +x Archivador/install.sh
cd Archivador && ./install.sh
```

O si prefieres, descarga el `Archivador.zip` del último release, descomprímelo y ejecuta `install.sh` dentro.

## Uso

- `waypaper` para cambiar el wallpaper → recolorea todo solo
- Botón en waybar para ocultar/mostrar el conky
- Widget de música con ⏮ ⏯ ⏭ y cava abajo
- Los colores de eww/conky se regeneran con el wallpaper

<img width="1279" height="719" alt="imagen" src="https://github.com/user-attachments/assets/602b09aa-db94-45e4-b53b-cc280a2a053e" />
<img width="1277" height="719" alt="imagen" src="https://github.com/user-attachments/assets/4ec39ce6-302c-4f4d-a9e3-9b514219c7dd" />
<img width="1279" height="719" alt="imagen" src="https://github.com/user-attachments/assets/65eebb35-1bf3-41db-9100-44c9abe522a0" />
<img width="1279" height="719" alt="imagen" src="https://github.com/user-attachments/assets/b5f3820e-229c-4635-b290-0afbc1a9c78b" />
