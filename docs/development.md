# Development

Plain bash, so it runs on a fresh Minimal Install with nothing extra. Every function is safe to run again; the
installer is re-run by `update`, so it must never overwrite what the user changed.

## Layout

```
install.sh              entry point: the full-screen installer, --plain, --dry-run, --scan
bin/
  update                one command for all updates
  keybinds              list and change keybindings
  noctalia-preset       switch looks, fetch their wallpapers
  monitors              arrange monitors (the installer's Monitors page on its own)
  open-default          start the default browser, file manager or editor (installed to /usr/local/bin)
  dock-watch            laptop panel off while docked, when chosen (installed to /usr/local/bin)
lib/
  common.sh             logging, ask/ask_once, copy_once/write_once/write_root, choices, state migration
  catalog.sh            the menus: every app, its source, packages and default; vendor repos
  drivers.sh            the driver scanner (reads /sys) and the driver rows
  keybinds.sh           the keybindings table and its translation into each compositor
  monitors.sh           monitors from /sys and their EDID, the layout, and its translation into each compositor
  packages.sh           repositories, the base package lists, the dnf transactions, Flatpaks
  apps.sh               apps that install themselves (JetBrains Toolbox, Claude Code, ArtCraft, npm/PyPI tools)
  user.sh               per-user config: compositor stubs, looks, default apps, migration
  system.sh             login screen, snapshots, power, services
  locale.sh, nvidia.sh  language and keyboard; the NVIDIA driver
  tui.sh                the full-screen installer
config/
  keybinds.tsv          the standard keybindings
  umbriel/ hypr/ niri/ mango/   compositor defaults (included by the user's own config)
  noctalia/             Noctalia defaults and the looks (presets/)
  xdg-desktop-portal/   portal settings per compositor
  ...                   terminals, GTK, MIME defaults, wallpapers, snapper
tests/                  unit tests (test_*.sh) and CI-only container checks
docs/                   these guides
```

## Conventions

- `copy_once`/`write_once` for files that become the user's; `write_root` for system files the installer owns;
  `ask_once` for questions, so a "no" is remembered. A one-time migration writes a marker in the state folder.
- The user's config files only include the repo defaults, so defaults can change without touching them.
- Nothing is removed that the user may have added: `remove_replaced_apps` skips when dnf would remove anything else,
  and unticking an app never uninstalls it.
- Stable before nightly: Fedora and RPM Fusion, then Terra (restricted with `includepkgs`), then vendor repos, COPR
  only for Hyprland, Flathub only without an RPM.
- Comments say why, in plain words, for someone reading the file later.

## Adding things

| To add | Where |
|---|---|
| An app | one line in `CATALOG` in `lib/catalog.sh` (see [Software](software.md)) |
| A menu | `CATEGORIES` in `lib/catalog.sh`; the installer builds its pages from it |
| A driver | a row in `DRIVERS` and a match in `hw_scan` (`lib/drivers.sh`) |
| A keybinding | a row in `config/keybinds.tsv`; a new window action needs a case in each `kb_*_action` |
| A look | `config/noctalia/presets/NAME.toml` with `# wallpaper =` and `# source =` lines |
| A compositor | a `desktop` row in the catalog, defaults in `config/NAME/`, a stub and portal file in `setup_compositors`, generators in `lib/keybinds.sh` and `lib/monitors.sh`, its session in `session_name`, its panel command in `bin/dock-watch` |

## Tests and CI

```bash
bash tests/run.sh                                     # every unit test
shellcheck install.sh bin/* lib/*.sh tests/*.sh       # lint
./install.sh --dry-run                                # what an install would do
```

The unit tests run without a Fedora machine: the TUI is rendered into a buffer at a fixed size, the driver scanner
runs on made-up hardware, package lists and generators are checked against the catalog.

CI (GitHub Actions) runs three jobs:

| Job | Checks |
|---|---|
| lint-and-test | shellcheck and every unit test |
| packages | in a Fedora 45 container with the real repos: every package of every menu and driver exists, every Flatpak, npm and PyPI package exists; the default install pulls in no other desktop, the fallbacks no other login manager |
| compositors | installs Umbriel, Hyprland, niri and MangoWC and has each validate the config, keybindings and monitor layout the installer writes |

To run a container check locally: `podman run --rm -v "$PWD":/repo:ro,Z fedora:45 bash -c 'cp -r /repo /work && cd /work && bash tests/compositors.sh'`.
