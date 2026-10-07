if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
end


# Recarga en vivo de los colores: apply-theme.sh manda SIGUSR1 a los shells
# interactivos cuando cambia el wallpaper, y aquí re-sourcéamos la paleta que
# matugen regeneró (z + conf.d/zzz_custom_theme.fish) sin reiniciar fish.
function __matugen_reload --on-signal SIGUSR1
    set -l f "$HOME/.config/fish/conf.d/zzz_custom_theme.fish"
    if test -f "$f"
        source "$f"
    end
end
