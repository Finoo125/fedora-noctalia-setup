# Monitors

Set where each monitor is, how it is turned and scaled, which ones are on, and what the laptop screen does while
docked: on the installer's **Monitors** page, or later with

```bash
monitors          # the same page, for the monitors connected now
monitors --list   # the monitors found and their layout, as text
```

The page shows a scaled preview of the arrangement and a line per monitor:

| Key | Does |
|---|---|
| ↑ ↓ | pick a monitor |
| ← → | move it left or right in the row |
| R | turn it: 0°, 90°, 180°, 270° (a portrait monitor is 90° or 270°) |
| S | scale: 1, 1.25, 1.5, 1.75, 2 |
| B | put it below the row, centered (a laptop under its external screens) |
| Space | on or off (the last screen that is on stays on) |
| A | align the row at the top, middle or bottom |
| L | the laptop screen while docked: on, as one more screen, or off |
| Enter | next page (`monitors`: save and apply) |

The layout applies to every compositor you installed, at once: niri, MangoWC and Umbriel reload by themselves,
Hyprland is told to.

## Laptops and docks

- **Configure while docked.** The page sees only the monitors connected at that moment. Installed without the dock?
  Plug it in and run `monitors`.
- **Ports don't matter.** External monitors are recognized by make, model and serial number from their EDID, so a
  USB-C dock that names them DP-5 today and DP-7 tomorrow keeps the layout. The laptop screen is recognized by its
  connector (`eDP-1`).
- **Docked and undocked both work.** Each monitor's settings apply only while it is connected. Undocked, the laptop
  screen is simply the only one.
- **Laptop screen while docked:**
  - **on** (the default): one more screen, wherever you put it, for example below the external monitors (B) or at the
    end of the row.
  - **off**: `dock-watch` turns it off the moment an external monitor is connected and back on when the last one is
    unplugged. Closing the lid while docked turns it off too, in both settings. (On Hyprland the same happens in
    `~/.config/hypr/monitors.lua`; lid handling there is left to Hyprland.)
- **Closing the lid** while docked doesn't suspend (systemd's default for docked laptops); undocked it suspends as
  usual.
- **Two places with different monitors** (home and office): each monitor keeps its own position, so set up each place
  once with `monitors`. The laptop screen has one position for both.

The mode is each monitor's preferred one (usually its native resolution at the highest refresh rate the compositor
picks). Mirroring isn't offered.

## Files

| File | |
|---|---|
| `~/.config/fedora-noctalia-setup/monitors.conf` | your layout (by monitor name), written by the page |
| `~/.config/umbriel/monitors.toml` | generated for Umbriel |
| `~/.config/niri/monitors.kdl` | generated for niri |
| `~/.config/mango/monitors.conf` | generated for MangoWC |
| `~/.config/hypr/monitors.lua` | generated for Hyprland (with the panel logic when "off while docked") |

The generated files are rewritten on every `install.sh` run and `monitors` save, and only once you have a layout:
until then each compositor arranges the monitors on its own. CI has every compositor validate the generated rules for a
docked laptop with a portrait monitor.
