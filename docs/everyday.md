# Everyday use

## Update

```bash
update
```

One command for everything: system packages (snapper takes a snapshot before and after), the NVIDIA module for a new
kernel, Flatpaks, firmware, the npm and PyPI tools, then it pulls this repo and runs `install.sh --plain`, so new
defaults, looks and fixes arrive. Your choices, keybindings and config files stay.

## Snapshots and backups

- **System:** snapper snapshots `/` before and after every package change. Browse and restore them in Btrfs Assistant
  → Snapper → root.
- **Boot menu (optional, Extras):** [grub-btrfs](https://github.com/Antynea/grub-btrfs) adds a **Fedora snapshots**
  submenu to GRUB, to start the system as it was before an update even when it no longer boots normally.
- **Your files (optional, Extras):** hourly snapshots of `/home`, 12 hourly and 7 daily kept. Restore a deleted or
  overwritten file from Btrfs Assistant → Snapper → home, or copy it out of `/home/.snapshots/<number>/snapshot/`
  without sudo.
- **Backups:** snapshots live on the same disk, so they don't survive a dead SSD or a lost laptop. Open **Pika
  Backup**, pick an external drive or a server, and turn on its schedule; its backups are encrypted and deduplicated.
- A monthly btrfs scrub reads every block and checks it, so a failing disk shows up before you need the backup.

## Power

Noctalia's power toggle switches TuneD profiles. **Balanced** runs at full speed on AC and switches to plain balanced
on battery (Fedora's default, balanced-battery, roughly doubles app start times). Pick **Power saver** when you need the
battery to last. On Intel CPUs thermald and the low-power-mode daemon run too.

## Monitors and docking

Arrange your monitors, turn them and choose whether the laptop screen stays on while docked with `monitors` (plug in
the dock first). See [Monitors](monitors.md).

## Your own changes

| Yours: created once, never overwritten | Rewritten on every `install.sh` run |
|---|---|
| Your compositor config (`~/.config/umbriel/config.toml`, `hypr/hyprland.lua`, `niri/config.kdl`, `mango/config.conf`): put overrides at the bottom | The generated keybindings (`~/.config/*/keybinds.*`): change keys with `keybinds` instead |
| `~/.config/ghostty/config`, `kitty/kitty.conf`, `btop/btop.conf`, `gtk-3.0`/`gtk-4.0` settings, `uwsm/env` | `~/.config/noctalia/10-fedora-noctalia-local.toml` (wallpaper folder and default) |
| `~/.config/mimeapps.list`, `~/.config/xdg-desktop-portal/*-portals.conf` | `~/.config/environment.d/60-fedora-noctalia-setup-gpu.conf` (NVIDIA only) |
| The KDE look (`kdeglobals`, `kcminputrc`, `kwalletrc`), set once | `/etc/greetd/config.toml`, `/var/lib/noctalia-greeter/greeter.toml` |
| `~/.config/fedora-noctalia-setup/monitors.conf` (your monitor layout) | The generated monitor files (`~/.config/*/monitors.*`): change them with `monitors` |
| `~/.config/fedora-noctalia-setup/keybinds.conf`, any other `~/.config/noctalia/*.toml`, `~/.config/noctalia-presets`, everything you change in Noctalia's Settings | `/usr/local/bin/open-default`, `/usr/local/bin/dock-watch` |

The defaults themselves live in this repo (`config/`) and arrive with `update`. To get a fresh copy of a file of
yours, delete it and run `install.sh`.

## Moving from fedora-hyprland

Clone this repo and run its `install.sh` on the fedora-hyprland machine. Once, it:

- carries over your answers and applied-once settings from `~/.local/state/fedora-hyprland`;
- removes fedora-hyprland's Noctalia layers and points the active look at this repo's presets;
- turns an Umbriel trial config into the layered one (your cursor comes along; the old file stays as
  `config.toml.fedora-hyprland`), and sends Flatpak passwords back to gnome-keyring;
- renames fedora-hyprland's system files (`/etc/sysctl.d`, the NVIDIA udev and modprobe files);
- unless you tick Hyprland: removes Hyprland, uwsm, hyprqt6engine, hyprpicker, nwg-look and the lionheartp COPR, and
  swaps the COPR's Luciole for Terra's (skipped with a warning if dnf would remove anything else). If you tick it, your
  Hyprland stays and its config is replaced by this repo's (the old one kept as `hyprland.lua.fedora-hyprland`).

`~/.config/hypr` and `~/.config/uwsm` stay for reference.
