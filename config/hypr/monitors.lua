-- Monitors: your layout from `monitors` (written to ~/.config/hypr/monitors.lua, which also turns the laptop panel
-- off while docked if you chose that), else Hyprland's automatic arrangement.
local generated = os.getenv("HOME") .. "/.config/hypr/monitors.lua"
local f = io.open(generated)
if f then
  f:close()
  dofile(generated)
else
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end
