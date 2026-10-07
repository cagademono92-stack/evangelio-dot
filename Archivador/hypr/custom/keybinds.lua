hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
-- ~/.config/hypr/custom/keybinds.lua
local mainMod = "SUPER"

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("ags request 'toggle-quicksettings'"))

hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("prismlauncher"), { description = "App: Launch PrismLauncher (AUR)" })
