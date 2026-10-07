-- Generado por matugen — NO editar a mano, se sobreescribe con cada wallpaper
hl.config({
    general = {
        col = {
            active_border   = "rgba({{colors.primary.default.hex_stripped}}FF)",
            inactive_border = "rgba({{colors.surface_variant.default.hex_stripped}}66)",
        },
    },
    misc = {
        background_color = "rgba({{colors.background.default.hex_stripped}}FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba({{colors.error.default.hex_stripped}}AA) rgba({{colors.tertiary.default.hex_stripped}}77)",
})