# The installer

`install.sh` turns a fresh minimal Fedora install into the desktop, and running it again is how changes and updates
are applied (`update` does that for you). Every step is safe to run twice: finished work is skipped.

## Before you start

1. Download the Fedora 45 **Everything** netinstall ISO and choose **Fedora Custom Operating System** under Software
   Selection (the minimal install; older Fedora releases called it **Minimal Install**). For Wi-Fi, also tick
   **Common NetworkManager Submodules**. Intel Wi-Fi chips additionally need firmware the minimal install leaves out
   and Fedora 45 no longer offers there, so on such a laptop connect a network cable or your phone (USB tethering)
   for the first run; the installer then adds the firmware.
2. Keep the default automatic partitioning (btrfs). Snapshots need it.
3. Pick your language, keyboard layout and timezone in the Fedora installer; the desktop uses them.
4. After the first boot, make sure you're online (`nmtui` for Wi-Fi).

```bash
sudo dnf install -y git
git clone https://github.com/Finoo125/fedora-noctalia-setup ~/.local/share/fedora-noctalia-setup
~/.local/share/fedora-noctalia-setup/install.sh
```

Run it as your normal user, not with sudo. It asks for your password once, right before it starts installing.

## The pages

In a terminal the installer is a full-screen program: the steps on the left, the current one on the right, the keys at
the bottom. Nothing changes on your system before you press **Install now** on the review page.

| Page | What you decide |
|---|---|
| Welcome | Shows what it found: Fedora version, btrfs, language, keyboard and timezone, drivers to set up, the login screen, an older fedora-hyprland install. |
| Compositors | Umbriel, Hyprland, niri, MangoWC: tick one or more; **D** picks the one the login screen starts. See [Compositors](compositors.md). |
| Fallback desktop | KDE Plasma and/or GNOME as a minimal backup session, or none. |
| Terminal ... Utilities | Twelve software menus with the popular apps for each job. **D** marks the default terminal, browser, file manager and editor. See [Software](software.md). |
| Drivers | What the hardware scan found and recommends. See [Drivers](drivers.md). |
| Extras | Fingerprint login (when a reader was found), hourly snapshots of `/home`, snapshots in the boot menu. |
| Monitors | Position, rotation, scale and on/off of each connected monitor, and the laptop screen while docked. See [Monitors](monitors.md). |
| Look | One of the 13 looks. See [Looks](looks.md). |
| Keybindings | Every keybinding; change any of them. See [Keybindings](keybindings.md). |
| Review | What will be added, set up and removed. **Show every package** lists them all. |
| Install | Each step with dnf's progress and the latest lines of the log. |
| Done | Enrolls your fingerprint if you ticked it, then reboots if you want. |

Keys: arrows (or j/k) move, **Space** ticks, **D** sets a default, **Enter** continues, **Backspace** goes back,
**Esc** quits. The window needs at least 80x24; on the Linux console the installer uses 16 colors and plain ASCII.

## Your choices

Everything you pick is saved in `~/.local/state/fedora-noctalia-setup/choices` (apps, drivers, defaults), and your
keybindings in `~/.config/fedora-noctalia-setup/keybinds.conf`. `update` installs the same apps again, so a new app
added to a menu you use doesn't appear by surprise, and nothing you unticked comes back. Unticking an app later doesn't
remove it if it is already installed.

## Without the full-screen installer

```bash
./install.sh --dry-run   # list the chosen apps, packages, repos and drivers; changes nothing
./install.sh --scan      # list the hardware that needs extra drivers
./install.sh --plain     # plain text, questions asked inline (what `update` runs)
./install.sh --help
```

Without a terminal (piped, or `ASSUME=yes ./install.sh`) it runs `--plain` and takes the defaults: Umbriel, the Plasma
fallback, the ticked apps, the recommended drivers. `NVIDIA=yes` or `NVIDIA=no` answers the NVIDIA question ahead.
sudo still needs your password: piped from a terminal it asks there; with no terminal at all (e.g. `ssh` without `-t`)
it stops right away unless sudo works without a password for you.

## What it does, in order

1. **Language and keyboard:** keeps what the Fedora installer set, adds the language pack.
2. **Repositories:** RPM Fusion, Terra (limited to the packages this setup uses, so it never replaces a Fedora
   package), Flathub, and only the vendor repos and COPRs your choices need.
3. **Packages:** one dnf transaction for the base, the compositors, the apps and the drivers; then the Qt theme and the
   fallback desktop in a second one without weak dependencies.
4. **Flatpak apps**, then **other apps** (JetBrains Toolbox, Claude Code, npm and PyPI tools, fonts, cursors).
5. **Your configuration:** config files written once (never overwritten), the compositor configs, keybindings, look,
   default apps.
6. **System:** login screen, fingerprint support, snapshots, power profiles, services.
7. **NVIDIA** when chosen, then the **optional steps** (snapshots of `/home`, the boot menu).

The full log is in `~/.cache/fedora-noctalia-setup/install.log`. If a step fails, fix the cause and run `install.sh`
again.
