# Software

Every app is chosen in a menu of the installer. Ticked by default (★) is a complete everyday desktop; everything else
is one Space away.

## Where apps come from

Stable first, in this order:

1. **Fedora and RPM Fusion** (`dnf`, `rpmfusion`): the stable builds of the release.
2. **Terra** (`terra`): apps Fedora and RPM Fusion don't package. Terra is limited with `includepkgs` to exactly these
   packages, so it never replaces a Fedora package.
3. **The vendor's own RPM repo** (`repo:NAME`): Brave, Vivaldi, Google Chrome, Microsoft Edge, VS Code, Docker; added
   only when you tick that app.
4. **A COPR** (`copr:NAME`): only Hyprland, which neither Fedora nor Terra carries.
5. **Flathub** (`flatpak`): only for apps without an RPM.
6. **npm and PyPI** (`npm`, `uvtool`): command-line AI agents that are only published there, installed for your user
   into `~/.local/bin` and brought up to date by `update`.

Each row of a menu shows its source.

## The menus

| Menu | Choices (★ ticked by default) |
|---|---|
| Compositors | Umbriel★, Hyprland, niri, MangoWC |
| Fallback desktop | KDE Plasma★, GNOME |
| Terminal | Ghostty★, kitty★, foot, Alacritty, Konsole |
| Browser | Firefox★, Chromium, Helium, Zen Browser, LibreWolf, Brave, Vivaldi, Google Chrome, Microsoft Edge, Ungoogled Chromium |
| Files | Luciole★, Dolphin★, Nautilus, Nemo, Thunar, PCManFM-Qt, Yazi |
| Office & text | Okular★, Kate★, Obsidian★, LibreOffice, OnlyOffice, Joplin, Papers, GNOME Text Editor, ArtCraft Launcher |
| Media | mpv★, Gwenview★, VLC, Celluloid, Haruna, Showtime, Loupe, qimgv, Elisa, Strawberry, Spotify |
| Creative & recording | OBS Studio, GIMP, Inkscape, Krita, Kdenlive, Shotcut, Blender, Audacity, darktable, HandBrake, ArtCraft Launcher |
| Communication | Thunderbird★, Telegram★, Discord★, Signal★, ZapZap★, Betterbird, Vesktop, Element, Slack, Zoom, Ferdium |
| Gaming | Steam★, game tools★ (GameMode, MangoHud, Gamescope, Winetricks), Lutris★, Heroic★, ProtonPlus★, Faugus★, Bottles, Prism Launcher |
| Development | VS Code★, Docker★, Podman + Distrobox★, JetBrains Toolbox★, DBeaver★, VSCodium, Zed, Neovim, Vim, Helix |
| Languages | C and C++★, Python★, JavaScript and TypeScript★, Deno, Java, Kotlin, Rust, Go, C# and .NET, PHP, Ruby, Zig, Lua, Swift, Dart, Flutter, Haskell, Elixir and Erlang, R, Julia, OCaml |
| AI agents | Claude Code★, Codex, Gemini CLI, GitHub Copilot CLI, OpenCode, Goose, Aider, Qwen Code, Crush, Cursor, Ollama, Jan |
| Utilities | Bitwarden★, Mission Center★, LocalSend★, Gear Lever★, Pika Backup★, Flatseal★, Printing★, KeePassXC, Syncthing, qBittorrent, Nextcloud |

Always installed: Noctalia and its login screen, Ark, KCalc, KDE Partition Manager, Discover, KDE Connect, pavucontrol,
Btrfs Assistant, the command-line basics (git, gh, btop, bat, eza, fzf, ripgrep, fd, zoxide, fastfetch), codecs,
printing and network-share support, fonts and the Papirus icons.

## Default apps

In the Terminal, Browser, Files and editor menus, **D** makes the highlighted app the default (★): the keybindings
(Super+Return, W, E, T) and "open with" follow it. The installer sets them through the system's own settings:
`~/.config/xdg-terminals.list` for the terminal, `xdg-settings` for the browser, `xdg-mime` for folders and text files.
An app's own "make default" button changes them too. `open-default browser|files|editor` starts whichever is the
default.

## Colors everywhere

Noctalia writes its colors for GTK 3/4, KDE (a color scheme), Ghostty, kitty, foot, Alacritty, btop, Luciole, Firefox
(with the [Pywalfox](https://addons.mozilla.org/firefox/addon/pywalfox/) add-on) and each compositor. Qt and KDE apps
read the KDE color scheme through the `kde` platform theme. Flatpaks get the same: GTK ones through adw-gtk3's Flatpak
theme, Qt ones through the KDE runtime's.

## Adding an app

One line in `lib/catalog.sh`:

```
"menus|id|label|default 1/0|role|source|packages|what it is"
"browser|zen|Zen Browser|0|browser|terra|zen-browser|Firefox-based, with vertical tabs and split view."
```

An app in two menus lists both (`creative,office`). CI then checks that every package exists in its repo and that
nothing pulls in another desktop.
