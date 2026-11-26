# Compositors and fallback desktops

The compositor draws the windows; Noctalia is the shell on top (bar, launcher, notifications, lock screen, wallpaper).
You can install several compositors and pick one on the login screen each time. The one marked ★ in the installer
starts by default.

| | Umbriel | Hyprland | niri | MangoWC |
|---|---|---|---|---|
| Style | Noctalia's own: effects, overview, five linked desks | dynamic tiling with animations and blur | scrollable tiling: columns on an endless strip | dwl-based, tags, scroller layout, blur |
| Package | `umbriel-nightly` | `hyprland` (with `uwsm`) | `niri` | `mangowm` |
| Source | Terra (nightly: no releases yet) | lionheartp COPR | Fedora | Terra |
| Portals | Umbriel + GTK | Hyprland + GTK | GNOME + GTK | wlr + GTK |
| Your config | `~/.config/umbriel/config.toml` | `~/.config/hypr/hyprland.lua` | `~/.config/niri/config.kdl` | `~/.config/mango/config.conf` |
| Repo defaults | `config/umbriel/defaults.toml` | `config/hypr/*.lua` | `config/niri/defaults.kdl` | `config/mango/defaults.conf` |
| Check a config | `umbriel config validate` | `Hyprland --verify-config` | `niri validate` | `mango -c FILE -p` |

**Hyprland** is not packaged by Fedora 45 or Terra. Hyprland's own wiki points Fedora users to the lionheartp COPR, so
that COPR is added when you tick Hyprland, and removed again (with fedora-hyprland's leftovers) when you don't.

## What every compositor gets

- Noctalia started with the session, and Noctalia's color template for that compositor, so borders and the overview
  follow the look.
- The same [keybindings](keybindings.md), including your changes.
- Passwords in gnome-keyring (also for Flatpaks, through the Secret portal) and file dialogs from Luciole, set in
  `~/.config/xdg-desktop-portal/<compositor>-portals.conf`.
- Qt and KDE apps in Noctalia's colors (`QT_QPA_PLATFORMTHEME=kde`), the Classic Pointer cursor, natural scrolling,
  and the system keyboard layout.
- X11 apps through xwayland-satellite (niri, MangoWC, Umbriel) or Hyprland's own XWayland.
- Your [monitor layout](monitors.md), with the laptop screen off while docked if you chose that.

## Your config and the defaults

The installer writes your config file once and never overwrites it. It only includes the repo defaults (and Noctalia's
colors) and has a "Your own changes go below this line" marker: what you add there wins over the defaults, and the
defaults update with `update`. Delete the file and run `install.sh` to get a fresh one.

- **Umbriel:** tables merge key by key; a list you set (like `general.autostart`) replaces the default list.
  `~/.config/umbriel/scripts/` links to `desks` (linked desks across monitors) and `open` (`open-default`; the names are the headings of Umbriel's keybinding overview).
- **Hyprland:** Lua (Hyprland 0.55 and newer). The defaults are modules in `config/hypr`; your `hyprland.lua`
  requires them. It runs through uwsm, whose environment is `~/.config/uwsm/env`. A fedora-hyprland stub found there
  is replaced once, the old one kept as `hyprland.lua.fedora-hyprland`.
- **niri:** `include` (niri 26.04 or newer); later settings win, binds override by key.
- **MangoWC:** `source=` lines; the keyboard layout and variant are written into your file because MangoWC doesn't read
  the system keymap.

## Fallback desktops

A fallback is a minimal desktop for when the compositor breaks after an update or a game misbehaves in it: pick it on
the login screen, run `update` or restore a snapshot from there, and switch back. Both install only the shell and its
settings, in their own dnf transaction without weak dependencies, so no extra apps and no second login manager come
along.

| | KDE Plasma | GNOME |
|---|---|---|
| Ticked by default | yes | no |
| Packages | plasma-workspace, plasma-desktop, KWin, System Settings, KScreen, network, sound, power, Bluetooth, polkit agent, KDE portal | GNOME Shell, its Wayland session, Settings, GNOME portal |
| Notes | Uses the same colors, icons and cursor; KWallet is off, passwords stay in gnome-keyring. Leave Plasma's Appearance settings alone: they change the same files that give the desktop its look. | GNOME Shell needs GDM's library, which ships in the `gdm` package; the installer keeps GDM switched off, so the login screen stays Noctalia's. |

You can tick both or none. The Qt theme plugin (`plasma-integration`) is installed either way, on its own and
without weak dependencies, so Qt apps keep Noctalia's colors without Plasma.

## The login screen

greetd with the Noctalia greeter, in the Ayu colors, with the first wallpaper of `config/wallpapers.txt`. It preselects the default
compositor; the others and the fallbacks are one click away.
