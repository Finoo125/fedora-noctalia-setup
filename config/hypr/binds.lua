-- Hyprland's own extra keybindings. The standard ones come from ~/.config/hypr/keybinds.lua (written from
-- config/keybinds.tsv and your changes; see `keybinds`), loaded at the end.
local mod = "SUPER"
local PORTRAIT = "desc:HP Inc. HP E27q G5"
local MAIN = "desc:HP Inc. HP X27i"

hl.bind(mod .. " + J", hl.dsp.layout("swapwithmaster"))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())
hl.bind(mod .. " + ALT + code:10", hl.dsp.focus({ monitor = PORTRAIT }))
hl.bind(mod .. " + ALT + code:11", hl.dsp.focus({ monitor = MAIN }))
hl.bind(mod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"))

local function zoom(delta)
  local z = hl.get_config("cursor.zoom_factor") + delta
  hl.config({ cursor = { zoom_factor = math.max(1.0, math.min(3.0, z)) } })
end
hl.bind(mod .. " + Minus", function() zoom(-0.3) end, { repeating = true })
hl.bind(mod .. " + Plus", function() zoom(0.3) end, { repeating = true })

local generated = os.getenv("HOME") .. "/.config/hypr/keybinds.lua"
local f = io.open(generated)
if f then
  f:close()
  dofile(generated)
end
