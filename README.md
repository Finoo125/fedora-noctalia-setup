# fedora-noctalia-setup

Turns a fresh **Fedora Minimal** install into a complete [Noctalia](https://github.com/noctalia-dev) desktop: the
Noctalia shell (bar, launcher, notifications, lock screen, wallpapers) and its login screen on the compositor you
choose (Umbriel, Hyprland, niri or MangoWC), with a minimal KDE Plasma or GNOME session as a fallback if you want
one. A full-screen installer lets you pick every app, driver, look and keybinding; one `update` command keeps it all
current.

[![CI](https://github.com/Finoo125/fedora-noctalia-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/Finoo125/fedora-noctalia-setup/actions/workflows/ci.yml)

## Install

On a fresh Fedora 45 minimal install (**Fedora Custom Operating System** in the Fedora installer; btrfs, online):

```bash
sudo dnf install -y git
git clone https://github.com/Finoo125/fedora-noctalia-setup ~/.local/share/fedora-noctalia-setup
~/.local/share/fedora-noctalia-setup/install.sh
systemctl reboot
```

Run it as your normal user. Nothing changes before you press **Install now** on its review page, and
`install.sh --dry-run` shows what it would do. Details: [The installer](docs/installer.md).

## What you get

- **Your compositor:** Umbriel (default), Hyprland, niri and/or MangoWC, each with the same keybindings, Noctalia,
  gnome-keyring and Luciole's file dialogs. Pick one on the login screen. → [Compositors](docs/compositors.md)
- **A fallback desktop**, optional: minimal KDE Plasma and/or GNOME, without extra apps or a second login manager,
  for when the compositor breaks after an update.
- **Your apps:** 14 menus with the popular choices for each job, from browsers and terminals to languages and AI
  agents. Stable sources first: Fedora and RPM Fusion, then Terra, then the vendor's own repo, Flathub only without an
  RPM. → [Software](docs/software.md)
- **Your drivers:** a hardware scan offers NVIDIA, AMD and Intel GPU drivers, Wi-Fi, webcams, input devices,
  controllers and smart card readers. → [Drivers](docs/drivers.md)
- **13 looks:** 4K wallpapers from anime to photography, pixel and flat art, with colors that follow them across the
  bar, apps, terminals and borders. → [Looks](docs/looks.md)
- **Your keybindings:** change any of them in the installer or with `keybinds set ACTION KEYS`.
  → [Keybindings](docs/keybindings.md)
- **Your monitors:** detected at install, arranged with a preview (position, rotation, scale), docked or not, with the
  laptop screen as one more monitor or off while docked. → [Monitors](docs/monitors.md)
- **Safety nets:** btrfs snapshots before and after every update, optionally snapshots in the boot menu and hourly
  snapshots of `/home`, Pika Backup for real backups. → [Everyday use](docs/everyday.md)

## Commands

| Command | What it does |
|---|---|
| `update` | Packages, Flatpaks, firmware, drivers and this repo's defaults, in one go |
| `noctalia-preset [NAME\|off]` | List or switch looks |
| `keybinds [set ACTION KEYS\|reset]` | List or change keybindings |
| `monitors` | Arrange monitors (plug in the dock first) |
| `install.sh --scan` | List the hardware that needs extra drivers |

## Documentation

- [The installer](docs/installer.md): before you start, the pages, your choices, plain mode
- [Compositors and fallback desktops](docs/compositors.md)
- [Software](docs/software.md): the menus, sources, default apps, adding an app
- [Drivers](docs/drivers.md): the hardware scan, NVIDIA and Secure Boot
- [Looks](docs/looks.md)
- [Keybindings](docs/keybindings.md): the defaults and how to change them
- [Monitors](docs/monitors.md): layout, rotation, laptops and docks
- [Everyday use](docs/everyday.md): update, snapshots and backups, power, monitors, your own changes, moving from
  fedora-hyprland
- [If something breaks](docs/troubleshooting.md)
- [Development](docs/development.md): layout, conventions, tests and CI

## Credits

- [Noctalia](https://github.com/noctalia-dev) (shell, Umbriel, Luciole, greeter), [Terra](https://terrapkg.com),
  [RPM Fusion](https://rpmfusion.org), [Hyprland](https://hypr.land), [niri](https://github.com/YaLTeR/niri),
  [MangoWC](https://github.com/mangowm/mango).
- Keybinding set originally from [CachyOS](https://github.com/CachyOS/cachyos-hypr-noctalia), written fresh.
- Installer layout inspired by [Abijspy/noctalia-installer](https://github.com/Abijspy/noctalia-installer), the
  [Noctalia Fedora Remix](https://sourceforge.net/projects/noctalia-fedora-remix/) and Dux Shell's installer.
- Wallpapers belong to their authors and are downloaded during install, not stored here: the looks' from
  [wallhaven.cc](https://wallhaven.cc), the others from
  [AngelJumbo/gruvbox-wallpapers](https://github.com/AngelJumbo/gruvbox-wallpapers),
  [D3Ext/aesthetic-wallpapers](https://github.com/D3Ext/aesthetic-wallpapers),
  [dharmx/walls](https://github.com/dharmx/walls),
  [vyrx-dev/Wallpapers](https://github.com/vyrx-dev/Wallpapers) and
  [JaKooLit/Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank).

## License

MIT for the code and configs in this repo. Wallpapers belong to their authors.
