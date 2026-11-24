# Keybindings

The same keybindings work in every compositor (Umbriel, Hyprland, niri, MangoWC). Super is the Windows key.

## Change them

- **In the installer:** the **Keybindings** page lists every action. Highlight one, press Enter, type the new keys
  (for example `Super+Shift+B`) and press Enter again. **R** puts the default back. Keys another action already uses
  are refused, with the name of that action, so nothing ends up bound twice.
- **Later, in a terminal:**

  ```bash
  keybinds                      # every action and its keys; * marks the ones you changed
  keybinds set browser Super+B  # change one
  keybinds reset browser        # back to the default (keybinds reset: all of them)
  ```

  Changes apply at once: niri, MangoWC and Umbriel reload their config by themselves, Hyprland is told to.

Keys are written as modifiers and a key joined with `+`. Modifiers: `Super`, `Ctrl`, `Alt`, `Shift` (`Win` and `Mod`
mean Super). Keys: letters, digits, `F1`–`F12`, `Return`, `Space`, `Escape`, `Tab`, `BackSpace`, `Delete`, `Home`,
`End`, `Page_Up`, `Page_Down`, the arrow keys (`Left`, `Right`, `Up`, `Down`), `Print`, `Period`, `Comma`, `Minus`,
`Plus`, `Equal`, `Slash` and the media keys (`XF86AudioRaiseVolume`, ...). Case doesn't matter.

## The defaults

**Windows**

| Keys | Action | Name for `keybinds` |
|---|---|---|
| `Super+Q` | Close window | `close` |
| `Super+Escape` | Force-close window | `kill` |
| `Super+Alt+Space` | Float or tile window | `float` |
| `Super+D` | Maximize window | `maximize` |
| `Super+F` | Fullscreen | `fullscreen` |
| `Super+Left` | Focus left | `focus-left` |
| `Super+Right` | Focus right | `focus-right` |
| `Super+Up` | Focus up | `focus-up` |
| `Super+Down` | Focus down | `focus-down` |
| `Super+Shift+Left` | Move window left | `move-left` |
| `Super+Shift+Right` | Move window right | `move-right` |
| `Super+Shift+Up` | Move window up | `move-up` |
| `Super+Shift+Down` | Move window down | `move-down` |
| `Alt+Tab` | Next window | `cycle` |
| `Super+Tab` | Window switcher | `switcher` |
| `Super+O` | Overview | `overview` |
| `Super+S` | Scratchpad | `scratchpad` |

**Desks**

| Keys | Action | Name for `keybinds` |
|---|---|---|
| `Super+1` | Desk 1 | `desk-1` |
| `Super+2` | Desk 2 | `desk-2` |
| `Super+3` | Desk 3 | `desk-3` |
| `Super+4` | Desk 4 | `desk-4` |
| `Super+5` | Desk 5 | `desk-5` |
| `Super+Shift+1` | Window to desk 1 | `to-desk-1` |
| `Super+Shift+2` | Window to desk 2 | `to-desk-2` |
| `Super+Shift+3` | Window to desk 3 | `to-desk-3` |
| `Super+Shift+4` | Window to desk 4 | `to-desk-4` |
| `Super+Shift+5` | Window to desk 5 | `to-desk-5` |
| `Super+Ctrl+Left` | Previous desk | `desk-prev` |
| `Super+Ctrl+Right` | Next desk | `desk-next` |
| `Super+Ctrl+Shift+Left` | Take window to previous desk | `carry-prev` |
| `Super+Ctrl+Shift+Right` | Take window to next desk | `carry-next` |

**Apps**

| Keys | Action | Name for `keybinds` |
|---|---|---|
| `Super+Return` | Terminal | `terminal` |
| `Super+E` | File manager | `files` |
| `Super+W` | Browser | `browser` |
| `Super+T` | Text editor | `editor` |
| `Super+C` | Calculator | `calculator` |
| `XF86Calculator` | Calculator (calculator key) | `calculator-key` |
| `Ctrl+Shift+Escape` | System monitor | `monitor` |

**Noctalia**

| Keys | Action | Name for `keybinds` |
|---|---|---|
| `Super+Space` | Launcher | `launcher` |
| `Super+Period` | Emoji picker | `emoji` |
| `Super+X` | Control center | `control-center` |
| `Super+Z` | Settings | `settings` |
| `Super+A` | Notifications | `notifications` |
| `Super+V` | Clipboard history | `clipboard` |
| `Super+L` | Lock screen | `lock` |
| `Super+Alt+C` | Session menu | `session` |
| `Super+Shift+W` | Wallpaper picker | `wallpaper` |
| `Print` | Screenshot of a region | `screenshot` |
| `Super+Print` | Screenshot of the screen | `screenshot-full` |
| `Super+Shift+S` | Start/stop screen recording | `record` |

**Hardware**

| Keys | Action | Name for `keybinds` |
|---|---|---|
| `XF86AudioRaiseVolume` | Volume up (also on the lock screen) | `volume-up` |
| `XF86AudioLowerVolume` | Volume down (also on the lock screen) | `volume-down` |
| `XF86AudioMute` | Mute (also on the lock screen) | `mute` |
| `XF86AudioMicMute` | Mute microphone (also on the lock screen) | `mic-mute` |
| `XF86AudioPlay` | Play/pause (also on the lock screen) | `play` |
| `XF86AudioNext` | Next track (also on the lock screen) | `next` |
| `XF86AudioPrev` | Previous track (also on the lock screen) | `previous` |
| `XF86MonBrightnessUp` | Brightness up (also on the lock screen) | `brightness-up` |
| `XF86MonBrightnessDown` | Brightness down (also on the lock screen) | `brightness-down` |

Super+E, Super+W and Super+T open your default file manager, browser and editor, and Super+Return your default
terminal: the ones marked with ★ in the installer (see [Software](software.md)), or later whatever you set with
`xdg-mime` or an app's "make default" button.

Each compositor also keeps a few of its own: mouse drag with Super+left/right button (all), Super+J swaps with the
main window (Umbriel, Hyprland), Super+Alt+1/2 focus the portrait/main monitor (Umbriel, Hyprland), Super+R cycles
column widths (niri), Super+Minus/Plus zoom (Hyprland), Super+P color picker (Hyprland), Super+Shift+Escape passes all
keys to the window, for games and VMs (Umbriel, niri), three-finger swipes switch desks (Umbriel, MangoWC). niri has
no scratchpad and Hyprland no overview, so those two keys do nothing there.

## How it works

`config/keybinds.tsv` is the one table of actions and default keys. Each action is a command (`spawn`), a Noctalia
command (`noctalia msg ...`) or a window action that `lib/keybinds.sh` translates into each compositor's own:

| Compositor | Generated file | Included by |
|---|---|---|
| Umbriel | `~/.config/umbriel/keybinds.toml` | `config/umbriel/defaults.toml` |
| niri | `~/.config/niri/keybinds.kdl` | `config/niri/defaults.kdl` |
| MangoWC | `~/.config/mango/keybinds.conf` | `config/mango/defaults.conf` |
| Hyprland | `~/.config/hypr/keybinds.lua` | `config/hypr/binds.lua` |

The generated files are rewritten on every `install.sh` run and `keybinds` change; don't edit them. Your changes live
in `~/.config/fedora-noctalia-setup/keybinds.conf` (`action=Keys` lines, only what differs from the defaults), which
`update` keeps. CI installs every compositor in a container and has it validate the generated bindings.
