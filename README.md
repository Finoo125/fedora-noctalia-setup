# fedora-noctalia-setup

One command turns a fresh **Fedora 45 Minimal** install into a complete **Noctalia** desktop: the
[Umbriel](https://docs.noctalia.dev/umbriel/) compositor, the Noctalia v5 shell (bar, launcher, notifications, lock
screen, wallpapers), the Noctalia login screen and Luciole, Noctalia's file manager. A minimal **KDE Plasma** session
is always installed next to it as a fallback, for when a nightly build breaks or a game misbehaves.

You also get Ayu colors everywhere, Papirus icons, Classic Pointer cursors (light and dark),
Ghostty and kitty (both in the desktop's colors), KDE apps in the desktop's colors (Dolphin with NAS shares,
Android/iPhone, cameras, NTFS/exFAT/Mac drives; Okular, Gwenview, Kate, Ark, KCalc, Partition Manager, Discover),
Firefox, codecs, gaming (Steam, Lutris, ProtonPlus, Heroic), dev tools (VS Code, JetBrains Toolbox, GitHub CLI, Docker,
Podman, Python 3.12–3.14, Node.js LTS), apps as RPMs where one exists (Flathub for the rest), fingerprint login,
printing with common printer drivers, VPN (OpenVPN, OpenConnect, WireGuard), automatic btrfs snapshots before every
update plus a monthly scrub, Pika Backup, and one `update` command for everything.

Successor to [fedora-hyprland](https://github.com/Finoo125/fedora-hyprland); see *Moving from fedora-hyprland*.

## Package sources

Stable releases first: Fedora and RPM Fusion, then [Terra](https://terrapkg.com). No COPRs, nothing built from source.

| Component | Package | Source | Channel |
|---|---|---|---|
| Shell | `noctalia` | Fedora updates | stable |
| Login screen | `noctalia-greeter` + `greetd` | Terra / Fedora | stable |
| Compositor | `umbriel-nightly` | Terra | nightly (Umbriel has no releases yet) |
| Portal | `xdg-desktop-portal-umbriel-nightly` | Terra | nightly (no releases yet) |
| File manager | `luciole-nightly` | Terra | nightly (no releases yet) |
| X11 apps | `xwayland-satellite` | Fedora updates | stable |
| Keyring | `gnome-keyring` (unlocked at login) | Fedora | stable |
| Fallback session | minimal KDE Plasma | Fedora | stable |

Terra is limited with `includepkgs` to these packages plus a few apps Fedora and RPM Fusion don't ship (Ghostty,
Signal, Heroic, ProtonPlus, Faugus, Mission Center), so it never replaces a Fedora package.

## Before you start

1. Download the Fedora 45 **Everything** netinstall ISO and choose **Minimal Install**.
   On a laptop without a network cable, also tick **Hardware Support** and **Common NetworkManager Submodules**,
   otherwise Wi-Fi doesn't work after the first boot.
2. Keep the default automatic partitioning (btrfs). Snapshots need it.
3. After the first boot, make sure you're online (`nmtui` for Wi-Fi).

## Install

```bash
sudo dnf install -y git
git clone https://github.com/Finoo125/fedora-noctalia-setup ~/.local/share/fedora-noctalia-setup
~/.local/share/fedora-noctalia-setup/install.sh
systemctl reboot
```

Run it as your normal user. In a terminal it opens a full-screen installer:

1. **Welcome:** what it found (Fedora version, btrfs, keyboard and timezone, GPU, login screen, an old fedora-hyprland).
2. **One menu per kind of software**, each with the popular choices and where they come from: Terminal, Browser,
   Files, Office & text, Media, Creative & recording, Communication, Gaming, Development, Languages, AI agents,
   Utilities. Tick any number;
   in the Terminal, Browser, Files and editor menus **D** marks the default app (★), which Super+Return, Super+W,
   Super+E, Super+T and "open with" follow.
3. **Drivers:** a scan of this machine's hardware (read from `/sys`, so it works on a fresh install) and what it needs:
   NVIDIA (RTX 20 and newer), AMD (Vulkan, video codecs; optional LACT and ROCm), Intel (video decoding, Vulkan;
   optional oneAPI compute, the NPU), Broadcom Wi-Fi, Intel IPU6 webcams, Logitech, Razer, Corsair and gaming mice,
   the Xbox Wireless Adapter, game controllers, smart card readers, rotation sensors, ASUS laptops. Recommended
   drivers are ticked. `./install.sh --scan` prints the same list.
4. **Extras:** fingerprint login (when a reader was found), hourly `/home` snapshots, snapshots in the boot menu.
5. **Look:** one of the `noctalia-preset` looks, or plain Ayu.
6. **Review:** what will be added, set up and removed. Nothing changes before **Install now**; **Show every package**
   lists them all.
7. **Install:** asks for your password once, then shows each step, dnf's progress and the latest log lines.
8. **Done:** enrolls the fingerprint if you ticked it, and reboots if you want.

Umbriel, Noctalia, the login screen, the Plasma fallback and the basic KDE tools (Ark, KCalc, Partition Manager,
Discover, KDE Connect) are always installed.

| Menu | Choices (★ ticked by default) |
|---|---|
| Terminal | Ghostty★, kitty★, foot, Alacritty, Konsole |
| Browser | Firefox★, Chromium, Helium, Zen Browser, LibreWolf, Brave, Vivaldi, Google Chrome, Microsoft Edge, Ungoogled Chromium |
| Files | Luciole★, Dolphin★, Nautilus, Nemo, Thunar, PCManFM-Qt, Yazi |
| Office & text | Okular★, Kate★, Obsidian★, LibreOffice, OnlyOffice, Joplin, Papers, GNOME Text Editor, ArtCraft Launcher |
| Media | mpv★, Gwenview★, VLC, Celluloid, Haruna, Showtime, Loupe, qimgv, Elisa, Strawberry, Spotify |
| Creative & recording | OBS Studio, GIMP, Inkscape, Krita, Kdenlive, Shotcut, Blender, Audacity, darktable, HandBrake, ArtCraft Launcher |
| Communication | Thunderbird★, Telegram★, Discord★, Signal★, ZapZap★, Betterbird, Vesktop, Element, Slack, Zoom, Ferdium |
| Gaming | Steam★, game tools★, Lutris★, Heroic★, ProtonPlus★, Faugus★, Bottles, Prism Launcher |
| Development | VS Code★, Docker★, Podman + Distrobox★, JetBrains Toolbox★, DBeaver★, VSCodium, Zed, Neovim, Vim, Helix |
| Languages | C and C++★, Python★, JavaScript and TypeScript★, Deno, Java, Kotlin, Rust, Go, C# and .NET, PHP, Ruby, Zig, Lua, Swift, Dart, Flutter, Haskell, Elixir and Erlang, R, Julia, OCaml |
| AI agents | Claude Code★, Codex, Gemini CLI, GitHub Copilot CLI, OpenCode, Goose, Aider, Qwen Code, Crush, Cursor, Ollama, Jan |
| Utilities | Bitwarden★, Mission Center★, LocalSend★, Gear Lever★, Pika Backup★, Flatseal★, Printing★, KeePassXC, Syncthing, qBittorrent, Nextcloud |

Sources, in this order: Fedora and RPM Fusion, then Terra, then the vendor's own RPM repo (Brave, Vivaldi, Google
Chrome, Microsoft Edge, VS Code, Docker; added only when you tick that app), and Flathub only for apps without an RPM.
AI agents that are only published on npm or PyPI are installed for your user into `~/.local/bin` and updated by
`update`.
The whole list lives in `lib/catalog.sh`.

Keys: arrows (or j/k) move, Space ticks, Enter continues, Backspace goes back, Esc quits. It needs a window of at
least 80x24; on the Linux console it uses 16 colors and plain ASCII.

Your choices are saved in `~/.local/state/fedora-noctalia-setup/choices`, so `update` installs the same apps.
Unticking an app later doesn't remove it if it is already installed.

```bash
./install.sh --dry-run   # list the packages and steps, change nothing
./install.sh --plain     # plain text, questions asked inline (what `update` runs)
./install.sh --scan      # list the hardware that needs extra drivers
```

A full log is kept in `~/.cache/fedora-noctalia-setup/install.log`. If something fails, fix it and run `install.sh`
again: finished steps are skipped.

Language, keyboard layout and timezone are the ones you picked in the Fedora installer (the plain installer offers to
change them). Umbriel and the login screen use the system keyboard layout. To change it later:
`sudo localectl set-x11-keymap us`, then `update`.

## Snapshots and backups

- **System:** snapper snapshots `/` before and after every package change (see *If something breaks*).
- **Boot menu (optional):** [grub-btrfs](https://github.com/Antynea/grub-btrfs) adds a **Fedora snapshots** submenu to
  GRUB, so you can start the system as it was before an update even when it no longer boots normally.
- **Your files (optional):** hourly snapshots of `/home`, 12 hourly and 7 daily kept. Restore a deleted or overwritten
  file from Btrfs Assistant → Snapper → home, or copy it out of `/home/.snapshots/<number>/snapshot/` without sudo.
- **Backups:** snapshots live on the same disk, so they don't survive a dead SSD or a lost laptop. Open **Pika Backup**,
  pick an external drive or a server, and turn on its schedule. Pika's backups are encrypted and deduplicated.

## Update

```bash
update
```

It upgrades system packages (snapper takes a snapshot before and after), rebuilds the NVIDIA module for a new kernel
if you have one, updates Flatpaks and firmware, pulls this repo and re-runs `install.sh` so new defaults arrive.

## Keybinds

The same set as fedora-hyprland (originally CachyOS's `cachyos-hypr-noctalia`). Super is the Windows key.

**Apps**

| Keys | Action |
|---|---|
| Super+Return | Ghostty (opens instantly: Ghostty keeps running in the background) |
| Super+E / W / T / C | Luciole / Firefox / Kate / KCalc |
| Calculator key | calculator |
| Ctrl+Shift+Escape | btop |

**Windows**

| Keys | Action |
|---|---|
| Super+Q, Super+Escape | close window, force-kill (click a window) |
| Super+F, Super+D, Super+Alt+Space | fullscreen, maximize, float |
| Super+J | swap with the main window |
| Super+arrows, Super+Shift+arrows | move focus, move window |
| Alt+Tab, Super+Tab | cycle windows, window switcher |
| Super+S | scratchpad |
| Super+mouse drag (left / right) | move / resize window |
| Super+O | overview (type to search apps) |
| Super+Shift+Escape | pass all keys to the window (games, VMs); press again to stop |

**Noctalia**

| Keys | Action |
|---|---|
| Super+Space, Super+. | launcher, emoji picker |
| Super+X, Super+Z, Super+A | control center, settings, notifications |
| Super+V | clipboard history |
| Super+L, Super+Alt+C | lock, session menu |
| Super+Shift+W | wallpaper picker |
| Print / Super+Print | screenshot of a region / of the screen |
| Super+Shift+S | start / stop screen recording (asks what to record; saved to ~/Videos/Recordings) |

**Hardware keys and touchpad.** Volume, mic, media and brightness keys also work on the lock screen.

| Keys | Action |
|---|---|
| Volume up / down / mute, mic mute | volume and microphone (hold to repeat) |
| Play/Pause, Next, Previous | media control |
| Brightness up / down | screen brightness (hold to repeat) |
| Three-finger swipe sideways | switch workspace |

**Desks:** there are five linked desks. Each desk is a pair of workspaces, one per monitor.
Every session starts on desk 1, so the first apps you open land there.

| Keys | Action |
|---|---|
| Super+1..5 | switch both monitors to desk 1–5 |
| Ctrl+Super+Left / Right | previous / next desk (stops at desk 1 and 5) |
| Super+Shift+1..5 | send the window to desk 1–5 on its monitor (you stay where you are) |
| Ctrl+Super+Shift+Left / Right | take the window to the previous / next desk (you go with it) |
| Super+Alt+1 / 2 | focus the portrait / main monitor |

## Monitors and docking

The layout is set up for two HP monitors, matched by model name, so it works on any dock port and with both laptops:

- **HP E27q G5**: portrait, on the left
- **HP X27i**: on the right, at the highest refresh rate the dock allows

When an external monitor is connected, the laptop screen turns off. When the last one is unplugged, it turns back on
immediately. One wallpaper spans both monitors.

To use other monitors, run `umbriel outputs` and add `[output."<make model serial>"]` sections to
`~/.config/umbriel/monitors.toml` (see the HP ones `scripts/dock.sh` writes there). If the portrait monitor shows the
picture upside down, change its `transform` from `"270"` to `"90"`.

## KDE apps and the Plasma fallback

The file manager is Luciole, Noctalia's own: folders open in it, file dialogs come from it, and it takes
Noctalia's colors directly. Dolphin stays for the Plasma session and for NAS shares and phones (KIO).

The other everyday apps are KDE's: Okular (PDFs), Gwenview (images), Kate (text), Ark (archives), KCalc,
KDE Partition Manager (disks) and Discover (apps). Noctalia writes its colors as a KDE color scheme, and
the kde Qt platform theme (plasma-integration) hands it to every Qt/KDE app in Umbriel together with Breeze,
Papirus and the desktop's fonts.
GTK apps (Firefox, Steam, pavucontrol) get the same colors through adw-gtk3 and Noctalia's GTK templates.
Flatpak apps get them too: GTK ones through adw-gtk3's Flatpak theme, Qt ones through the KDE runtime's theme.
Firefox needs the [Pywalfox](https://addons.mozilla.org/firefox/addon/pywalfox/) add-on to follow the colors.
File dialogs are KDE's too, so they match.

**KDE Plasma** is always installed as a minimal session (no extra apps, no second login manager) for when Umbriel
breaks after an update or a game runs badly in it. Pick **Plasma** on the login screen instead of Umbriel. It uses the
same color scheme, icons and cursor, and the same keyring (gnome-keyring; KWallet is turned off), so saved passwords
work in both. Leave Plasma's Appearance settings alone: they change the same files that give Umbriel its look.

## Looks

`noctalia-preset` switches the whole look in one go: palette, bar, panels, desktop widgets and wallpaper. The colors
come from the wallpaper, so the apps (Ghostty, kitty, GTK, KDE, Luciole, Firefox) change with it.

```bash
noctalia-preset            # list the looks; * marks the active one
noctalia-preset waterfall  # use one
noctalia-preset off        # back to Ayu and the wallpaper you had before
```

| Look | Wallpaper | Style |
|---|---|---|
| `waterfall` | forest gorge with a turquoise lake | teal, capsule bar, see-through panels; time at the top, calendar and music on the right |
| `island`, `lagoon`, `seaside`, `coast` | island, tropical lagoon, village street to the sea, coastal town | the waterfall style with other blue wallpapers |
| `dusk` | golden field at sunset | warm, floating bar, soft panels |
| `night` | the same field at night | deep blue, no bar background (only the capsules), see-through panels |

A look is a Noctalia config file in `config/noctalia/presets` with a `# wallpaper = PATH` line; the active one is
linked as `~/.config/noctalia/30-preset.toml`, so it updates with `update`. Your own go in `~/.config/noctalia-presets`
and win over a repo look of the same name. The widget positions are made for a 1920x1080 screen; move them with
Settings → Desktop → Toggle Editor (they are then saved in Noctalia's settings).

## Power profiles

Noctalia's power toggle switches TuneD profiles. **Balanced** runs at full speed on AC and switches to plain
balanced on battery. Fedora's default is the more aggressive balanced-battery, which roughly doubles app start
times. Pick **Power saver** when you need the battery to last.

## Your own changes

| Yours (created once, never overwritten) | Regenerated on every install.sh run |
|---|---|
| `~/.config/umbriel/config.toml` (includes the repo defaults; put overrides at the bottom) | `~/.config/environment.d/60-fedora-noctalia-setup-gpu.conf` (NVIDIA only) |
| `~/.config/ghostty/config`, `~/.config/kitty/kitty.conf`, `~/.config/btop/btop.conf`, `~/.config/gtk-*/settings.ini` | `~/.config/noctalia/10-fedora-noctalia-local.toml` |
| `~/.config/mimeapps.list`, `~/.config/xdg-desktop-portal/*-portals.conf`, `~/.config/umbriel/monitors.toml` | `/etc/greetd/config.toml`, `/var/lib/noctalia-greeter/greeter.toml` |
| KDE look (`kdeglobals`, `kcminputrc`, `kwalletrc`), set once | |
| any other `~/.config/noctalia/*.toml` (`30-preset.toml` is the active look), `~/.config/noctalia-presets`, and everything you change in Noctalia's Settings | |

The defaults themselves live in this repo (`config/`) and arrive with `update`. In `~/.config/umbriel/config.toml`,
tables merge key by key with the defaults, but a list you set (like `general.autostart`) replaces the default list.
`~/.config/umbriel/scripts/` holds links to this repo's scripts; a script you replace with your own file stays.

## Moving from fedora-hyprland

Clone this repo and run its `install.sh` on the fedora-hyprland machine. Once, it:

- removes Hyprland, uwsm, hyprqt6engine, hyprpicker, nwg-look and the lionheartp COPR, and swaps the COPR's Luciole
  for Terra's (skipped with a warning if dnf would remove anything else);
- carries over your answers and applied-once settings from `~/.local/state/fedora-hyprland`;
- removes fedora-hyprland's Noctalia layers and points the active look at this repo's presets;
- turns the Umbriel trial's config into the layered one (your cursor comes along; the old file stays as
  `config.toml.fedora-hyprland`), and sends Flatpak passwords back to gnome-keyring;
- renames fedora-hyprland's system files (`/etc/sysctl.d`, NVIDIA udev and modprobe files).

`~/.config/hypr` and `~/.config/uwsm` stay for reference; delete them when you no longer need them.

## NVIDIA (RTX 20 to RTX 50)

**Untested on real hardware so far.** If the installer finds an RTX 20–50 or GTX 16 card, it offers RPM Fusion's driver
(open kernel modules, CUDA, NVENC, Steam 32-bit libraries, suspend fixes). `NVIDIA=yes` or `NVIDIA=no` skips the question.
Older cards get a pointer to RPM Fusion's legacy driver.

- **Secure Boot:** you set a one-time password. After the reboot a blue **MOK management** screen appears:
  Enroll MOK → Continue → Yes → password → Reboot. That screen uses a **US keyboard layout**, so use only letters a–x
  and digits in the password.
- **Hybrid laptops:** the desktop runs on the integrated GPU. Start a game on the NVIDIA GPU with `nvidia-run <app>`,
  or the Steam launch option `nvidia-run %command%`.

## If something breaks

- **Bad update:** open Btrfs Assistant → Snapper, and restore the snapshot taken before the update.
- **Bad update and it won't boot:** in GRUB, open **Fedora snapshots** and pick the snapshot from before the update.
  `/boot` isn't part of the snapshots, so choose a kernel that was already installed back then (the older ones in the
  list). The snapshot starts read-only and some services may complain. That's expected. Open Btrfs Assistant, restore
  that snapshot and reboot. **Untested on real hardware so far.**
- **Umbriel itself is broken:** pick **Plasma** on the login screen, run `update` in Ghostty there, or restore
  a snapshot with Btrfs Assistant.
- **Won't boot to the desktop:** pick the previous kernel in the GRUB menu, or switch to a text console with
  Ctrl+Alt+F3, log in, and look at `~/.cache/fedora-noctalia-setup/install.log`.

## Credits

- Keybind set originally from [CachyOS](https://github.com/CachyOS/cachyos-hypr-noctalia), written fresh.
- [Noctalia](https://github.com/noctalia-dev) (shell, Umbriel, Luciole, greeter) and [Terra](https://terrapkg.com).
- Installer layout inspired by [Abijspy/noctalia-installer](https://github.com/Abijspy/noctalia-installer) and the
  [Noctalia Fedora Remix](https://sourceforge.net/projects/noctalia-fedora-remix/).
- Wallpapers belong to their authors and are downloaded from their repos during install, not stored here:
  [AngelJumbo/gruvbox-wallpapers](https://github.com/AngelJumbo/gruvbox-wallpapers),
  [D3Ext/aesthetic-wallpapers](https://github.com/D3Ext/aesthetic-wallpapers),
  [dharmx/walls](https://github.com/dharmx/walls),
  [vyrx-dev/Wallpapers](https://github.com/vyrx-dev/Wallpapers),
  [JaKooLit/Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank).

## License

MIT for the code and configs in this repo. Wallpapers belong to their authors.
