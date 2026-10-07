-- Conky: flotante, sin borde ni sombra, fijado al fondo del escritorio
hl.window_rule({match = {class = "^(conky)$" }, float = true})
hl.window_rule({match = {class = "^(conky)$" }, pin = true})
hl.window_rule({match = {class = "^(conky)$" }, no_shadow = true})
hl.window_rule({match = {class = "^(conky)$" }, no_blur = false})
hl.window_rule({match = {class = "^(conky)$" }, border_size = 0})
