# shellcheck shell=bash
# The software menus: every optional app, its menu, where it comes from and whether it is ticked by default.
# Stable first: Fedora ("dnf") and RPM Fusion ("rpmfusion"), then Terra ("terra"), then the vendor's own RPM repo ("repo:NAME"),
# Flathub only for apps without an RPM ("flatpak"). "copr:NAME" for Hyprland, which Fedora and Terra don't carry
# (Hyprland's own wiki points Fedora to that COPR); the COPR is only added when Hyprland is chosen. "noweak" installs
# in its own transaction without weak dependencies: the fallback desktops stay minimal, with no second login manager. "script" runs a function (lib/apps.sh); "npm" and "uvtool" install
# command-line tools for your user (~/.local/bin) with npm or uv, which come along. An app in two menus lists both
# ("creative,office").

# Menus in order: "id|title".
CATEGORIES=("desktop|Compositors" "fallback|Fallback desktop" "terminal|Terminal" "browser|Browser" "files|Files" "office|Office & text" "media|Media"
  "creative|Creative & recording" "chat|Communication" "gaming|Gaming" "dev|Development" "langs|Languages"
  "ai|AI agents" "utils|Utilities")

# "menus|id|label|default 1/0|role|source|packages|what it is". A role (terminal, browser, files, editor) means it can
# be the default app for that job; the keybinds and "open with" follow the default. "session" is the compositor the
# login screen starts.
CATALOG=(
  "desktop|umbriel|Umbriel|1|session|terra|umbriel-nightly xdg-desktop-portal-umbriel-nightly xwayland-satellite|Noctalia's own compositor: effects, overview, linked desks. Nightly build from Terra."
  "desktop|hyprland|Hyprland|0|session|copr:lionheartp/Hyprland|hyprland hyprland-uwsm uwsm xdg-desktop-portal-hyprland hyprland-guiutils hyprpicker|Dynamic tiling with animations and blur. From the lionheartp COPR, which Hyprland recommends for Fedora."
  "desktop|niri|niri|0|session|dnf|niri xdg-desktop-portal-gnome xwayland-satellite|Scrollable tiling: windows in columns on an endless strip. Fedora's own package."
  "desktop|mango|MangoWC|0|session|terra|mangowm xdg-desktop-portal-wlr xwayland-satellite|Light dwl-based compositor with tags, scroller layout and blur. From Terra."

  "fallback|plasma|KDE Plasma|1||noweak|plasma-workspace plasma-desktop kwin plasma-systemsettings kscreen plasma-nm plasma-pa powerdevil bluedevil polkit-kde xdg-desktop-portal-kde|Minimal Plasma session on the login screen, for when the compositor or a game misbehaves. Same colors and passwords."
  "fallback|gnome|GNOME|0||noweak|gnome-shell gnome-session-wayland-session gnome-control-center xdg-desktop-portal-gnome|Minimal GNOME session on the login screen: the shell and its settings, no extra apps, no GDM."

  "terminal|ghostty|Ghostty|1|terminal|terra|ghostty|Fast GPU terminal, tabs and splits, in the desktop's colors."
  "terminal|kitty|kitty|1|terminal|dnf|kitty|GPU terminal with images, tabs and layouts, in the desktop's colors."
  "terminal|foot|foot|0|terminal|dnf|foot|Small and fast Wayland terminal."
  "terminal|alacritty|Alacritty|0|terminal|dnf|alacritty|Minimal GPU terminal, configured in one file."
  "terminal|konsole|Konsole|0|terminal|dnf|konsole|KDE's terminal, with profiles and tabs."

  "browser|firefox|Firefox|1|browser|dnf|firefox|Mozilla's browser; follows the desktop's colors with Pywalfox."
  "browser|chromium|Chromium|0|browser|dnf|chromium|The open-source base of Chrome, built by Fedora."
  "browser|helium|Helium|0|browser|terra|helium-browser-bin|Chromium without the bloat, with uBlock Origin built in."
  "browser|zen|Zen Browser|0|browser|terra|zen-browser|Firefox-based, with vertical tabs and split view."
  "browser|librewolf|LibreWolf|0|browser|terra|librewolf|Firefox with privacy settings and no telemetry."
  "browser|brave|Brave|0|browser|repo:brave|brave-browser|Chromium-based, blocks ads and trackers. Brave's own repo."
  "browser|vivaldi|Vivaldi|0|browser|repo:vivaldi|vivaldi-stable|Chromium-based, very customizable, mail built in. Vivaldi's repo."
  "browser|chrome|Google Chrome|0|browser|repo:chrome|google-chrome-stable|Google's browser, from Google's repo."
  "browser|edge|Microsoft Edge|0|browser|repo:edge|microsoft-edge-stable|Microsoft's browser, from Microsoft's repo."
  "browser|ungoogled|Ungoogled Chromium|0|browser|flatpak|io.github.ungoogled_software.ungoogled_chromium|Chromium without Google services."

  "files|luciole|Luciole|1|files|terra|luciole-nightly|Noctalia's file manager, also the file dialogs. Nightly build."
  "files|dolphin|Dolphin|1|files|dnf|dolphin|KDE's file manager: network shares, phones, cameras; Plasma uses it."
  "files|nautilus|Nautilus|0|files|dnf|nautilus|GNOME's file manager."
  "files|nemo|Nemo|0|files|dnf|nemo|Cinnamon's file manager, two panes."
  "files|thunar|Thunar|0|files|dnf|Thunar thunar-archive-plugin thunar-volman|Xfce's light file manager."
  "files|pcmanfm|PCManFM-Qt|0|files|dnf|pcmanfm-qt|Very light Qt file manager."
  "files|yazi|Yazi|0||terra|yazi|File manager in the terminal, with previews."

  "office|okular|Okular|1||dnf|okular|PDFs, e-books and comics, with notes and forms."
  "office|kate|Kate|1|editor|dnf|kate|KDE's text editor, with tabs, sessions and a terminal."
  "office|obsidian|Obsidian|1||flatpak|md.obsidian.Obsidian|Notes in Markdown files, linked together."
  "office|libreoffice|LibreOffice|0||dnf|libreoffice-writer libreoffice-calc libreoffice-impress|Documents, spreadsheets, presentations; opens MS Office files."
  "office|onlyoffice|OnlyOffice|0||flatpak|org.onlyoffice.desktopeditors|Office suite close to MS Office's look."
  "office|joplin|Joplin|0||flatpak|net.cozic.joplin_desktop|Open-source notes with sync and end-to-end encryption."
  "office|papers|Papers|0||dnf|papers|GNOME's PDF viewer."
  "office|texteditor|GNOME Text Editor|0|editor|dnf|gnome-text-editor|Simple GNOME text editor."

  "media|mpv|mpv|1||dnf|mpv mpv-mpris|Plays any video; media keys work."
  "media|vlc|VLC|0||dnf|vlc|The classic player: any format, streams, DVDs."
  "media|celluloid|Celluloid|0||dnf|celluloid|mpv with a simple GTK window."
  "media|haruna|Haruna|0||dnf|haruna|mpv with a KDE window and playlists."
  "media|showtime|Showtime|0||dnf|showtime|GNOME's minimal video player."
  "media|gwenview|Gwenview|1||dnf|gwenview|KDE's image viewer, with simple edits."
  "media|loupe|Loupe|0||dnf|loupe|GNOME's image viewer."
  "media|qimgv|qimgv|0||dnf|qimgv|Fast image viewer, also GIFs and videos."
  "media|elisa|Elisa|0||dnf|elisa-player|KDE's music player."
  "media|strawberry|Strawberry|0||dnf|strawberry|Music collection player, for big libraries."
  "media|spotify|Spotify|0||flatpak|com.spotify.Client|Spotify's own app."

  "creative|obs|OBS Studio|0||dnf|obs-studio|Screen recording and streaming."
  "creative|gimp|GIMP|0||dnf|gimp|Photo editing."
  "creative|inkscape|Inkscape|0||dnf|inkscape|Vector graphics."
  "creative|krita|Krita|0||dnf|krita|Digital painting."
  "creative|kdenlive|Kdenlive|0||dnf|kdenlive|Video editing (KDE)."
  "creative|shotcut|Shotcut|0||dnf|shotcut|Video editing, simpler."
  "creative|blender|Blender|0||dnf|blender|3D modeling, animation, rendering."
  "creative|audacity|Audacity|0||dnf|audacity|Audio recording and editing."
  "creative|darktable|darktable|0||dnf|darktable|Raw photo development."
  "creative|handbrake|HandBrake|0||rpmfusion|HandBrake-gui|Video converter."
  "creative,office|artcraft|ArtCraft Launcher|0||script|install_artcraft|Alpha creative apps; AppImage checked against its checksum."

  "chat|thunderbird|Thunderbird|1||dnf|thunderbird|Mail, calendar and contacts."
  "chat|betterbird|Betterbird|0||flatpak|eu.betterbird.Betterbird|Thunderbird with extra features."
  "chat|telegram|Telegram|1||rpmfusion|telegram-desktop|Telegram's desktop app."
  "chat|discord|Discord|1||rpmfusion|discord|Discord's app."
  "chat|vesktop|Vesktop|0||terra|vesktop|Discord with screen sharing that works on Wayland."
  "chat|signal|Signal|1||terra|signal-desktop|Signal's desktop app."
  "chat|zapzap|ZapZap|1||flatpak|com.rtosta.zapzap|WhatsApp Web as an app."
  "chat|element|Element|0||flatpak|im.riot.Riot|Matrix chat."
  "chat|slack|Slack|0||flatpak|com.slack.Slack|Slack's app."
  "chat|zoom|Zoom|0||flatpak|us.zoom.Zoom|Zoom's app."
  "chat|ferdium|Ferdium|0||flatpak|org.ferdium.Ferdium|All your messengers and web apps in one window."

  "gaming|steam|Steam|1||rpmfusion|steam|Valve's store and Proton."
  "gaming|gametools|Game tools|1||dnf|gamemode mangohud gamescope protontricks winetricks vulkan-tools|GameMode, MangoHud, Gamescope, Winetricks."
  "gaming|lutris|Lutris|1||dnf|lutris|All stores and Windows games in one place."
  "gaming|heroic|Heroic|1||terra|heroic-games-launcher|Epic, GOG and Amazon games."
  "gaming|protonplus|ProtonPlus|1||terra|protonplus|Installs Proton-GE and other Proton builds."
  "gaming|faugus|Faugus Launcher|1||terra|faugus-launcher|Simple launcher for Windows games."
  "gaming|bottles|Bottles|0||dnf|bottles|Windows apps in separate Wine prefixes."
  "gaming|prism|Prism Launcher|0||terra|prismlauncher|Minecraft with many instances and mods."

  "dev|vscode|VS Code|1|editor|repo:vscode|code|Microsoft's code editor, from Microsoft's repo."
  "dev|docker|Docker|1||repo:docker|docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin|Docker Engine and Compose; starts on first use."
  "dev|podman|Podman + Distrobox|1||dnf|podman distrobox|Containers without a daemon; other distros in a box."
  "dev|jetbrains|JetBrains Toolbox|1||script|install_jetbrains_toolbox|Installs and updates IntelliJ, PyCharm and friends."
  "dev|dbeaver|DBeaver|1||flatpak|io.dbeaver.DBeaverCommunity|Database client."
  "dev|codium|VSCodium|0|editor|terra|codium|VS Code without Microsoft's telemetry."
  "dev|zed|Zed|0|editor|terra|zed|Fast editor with collaboration and AI."
  "dev|neovim|Neovim|0||dnf|neovim|Vim, modernized."
  "dev|vim|Vim|0||dnf|vim-enhanced|The classic."
  "dev|helix|Helix|0||dnf|helix|Modal editor with language support built in."

  "langs|cpp|C and C++|1||dnf|gcc gcc-c++ make cmake gdb clang|GCC, Clang, Make, CMake and GDB."
  "langs|python|Python|1||dnf|uv python3 python3.12 python3.13|Python 3.12 to 3.14 and uv."
  "langs|node|JavaScript and TypeScript|1||dnf|nodejs24 nodejs24-npm pnpm typescript|Node.js 24 LTS, npm, pnpm and TypeScript."
  "langs|deno|Deno|0||terra|deno|JavaScript and TypeScript runtime with tooling built in."
  "langs|java|Java|0||dnf|java-25-openjdk-devel maven|OpenJDK 25 LTS and Maven."
  "langs|kotlin|Kotlin|0||terra|kotlin gradle|Kotlin compiler and Gradle."
  "langs|rust|Rust|0||dnf|rust cargo rustfmt clippy rust-analyzer|Fedora's Rust toolchain with Cargo, Clippy and rust-analyzer."
  "langs|go|Go|0||dnf|golang|The Go toolchain."
  "langs|dotnet|C# and .NET|0||dnf|dotnet-sdk-10.0|.NET 10 SDK."
  "langs|php|PHP|0||dnf|php-cli composer|PHP 8 and Composer."
  "langs|ruby|Ruby|0||dnf|ruby ruby-devel rubygem-bundler|Ruby and Bundler."
  "langs|zig|Zig|0||dnf|zig|Zig compiler."
  "langs|lua|Lua|0||dnf|lua luarocks|Lua and LuaRocks."
  "langs|swift|Swift|0||dnf|swift-lang|Swift toolchain."
  "langs|dart|Dart|0||terra|dart|Dart SDK."
  "langs|flutter|Flutter|0||terra|flutter|Flutter SDK for apps on every platform."
  "langs|haskell|Haskell|0||dnf|ghc cabal-install|GHC and Cabal."
  "langs|elixir|Elixir and Erlang|0||dnf|elixir erlang|Elixir on the Erlang VM."
  "langs|r|R|0||dnf|R|Statistics and data analysis."
  "langs|julia|Julia|0||dnf|julia|Fast numeric computing."
  "langs|ocaml|OCaml|0||dnf|ocaml opam|OCaml and opam."

  "ai|claude|Claude Code|1||script|install_claude_code|Anthropic's coding agent in the terminal."
  "ai|codex|Codex|0||terra|codex|OpenAI's coding agent in the terminal."
  "ai|gemini|Gemini CLI|0||npm|@google/gemini-cli|Google's coding agent in the terminal."
  "ai|copilot|GitHub Copilot CLI|0||npm|@github/copilot|GitHub's coding agent in the terminal."
  "ai|opencode|OpenCode|0||terra|opencode|Open-source coding agent for any model provider."
  "ai|goose|Goose|0||dnf|goose|Open-source agent for code and everyday tasks, any model."
  "ai|aider|Aider|0||uvtool|aider-chat|Pair programming in the terminal, commits with git."
  "ai|qwen|Qwen Code|0||npm|@qwen-code/qwen-code|Alibaba's coding agent for Qwen models."
  "ai|crush|Crush|0||npm|@charmland/crush|Charm's coding agent with a terminal UI."
  "ai|cursor|Cursor|0|editor|terra|cursor|Code editor built around AI."
  "ai|ollama|Ollama|0||dnf|ollama|Run language models locally."
  "ai|jan|Jan|0||flatpak|ai.jan.Jan|Desktop chat app for local and cloud models."

  "utils|bitwarden|Bitwarden|1||flatpak|com.bitwarden.desktop|Password manager with sync."
  "utils|keepassxc|KeePassXC|0||dnf|keepassxc|Password manager in a local file."
  "utils|missioncenter|Mission Center|1||terra|mission-center|CPU, memory, disk and GPU monitor."
  "utils|localsend|LocalSend|1||flatpak|org.localsend.localsend_app|Send files to phones and PCs nearby."
  "utils|gearlever|Gear Lever|1||flatpak|it.mijorus.gearlever|Manages AppImages."
  "utils|pika|Pika Backup|1||flatpak|org.gnome.World.PikaBackup|Encrypted backups to a drive or server."
  "utils|flatseal|Flatseal|1||dnf|flatseal|Flatpak permissions."
  "utils|printing|Printing|1||dnf|cups cups-pk-helper cups-pdf hplip gutenprint-cups foomatic-db system-config-printer|CUPS with HP, Gutenprint and common drivers, and a PDF printer."
  "utils|syncthing|Syncthing|0||dnf|syncthing|Sync folders between your devices, no cloud."
  "utils|qbittorrent|qBittorrent|0||dnf|qbittorrent|Torrent client."
  "utils|nextcloud|Nextcloud|0||dnf|nextcloud-client|Desktop sync for a Nextcloud server."
)

# Vendor repos for "repo:NAME", added only when an app from them is chosen.
VSCODE_REPO='[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc'
EDGE_REPO='[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc'

# setup_vendor_repo NAME: adds a vendor's RPM repo (safe to run again).
setup_vendor_repo() {
  case "$1" in
    vscode)
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      write_root /etc/yum.repos.d/vscode.repo "$VSCODE_REPO"
      ;;
    edge)
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      write_root /etc/yum.repos.d/microsoft-edge.repo "$EDGE_REPO"
      ;;
    docker)
      [[ -f /etc/yum.repos.d/docker-ce.repo ]] ||
        sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
      ;;
    brave)
      [[ -f /etc/yum.repos.d/brave-browser.repo ]] ||
        sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
      ;;
    vivaldi)
      [[ -f /etc/yum.repos.d/vivaldi-fedora.repo ]] ||
        sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/archive/vivaldi-fedora.repo
      ;;
    chrome)
      # Fedora ships Google's repo, switched off; this switches it on.
      sudo dnf install -y fedora-workstation-repositories
      sudo dnf config-manager setopt google-chrome.enabled=1
      ;;
    *) warn "No vendor repo named $1." ;;
  esac
}

# The catalog as lookup tables, built once: CAT_<FIELD>[id]; CAT_IDS keeps the order.
declare -gA CAT_MENU CAT_LABEL CAT_DEFAULT CAT_ROLE CAT_SOURCE CAT_PACKAGES CAT_ABOUT
CAT_IDS=()
catalog_index() {
  local entry menu id label def role source pkgs about
  for entry in "${CATALOG[@]}"; do
    IFS='|' read -r menu id label def role source pkgs about <<<"$entry"
    CAT_IDS+=("$id")
    CAT_MENU[$id]=$menu CAT_LABEL[$id]=$label CAT_DEFAULT[$id]=$def CAT_ROLE[$id]=$role
    CAT_SOURCE[$id]=$source CAT_PACKAGES[$id]=$pkgs CAT_ABOUT[$id]=$about
  done
}
catalog_index

# catalog_ids [MENU] -> app ids, in menu order.
catalog_ids() {
  local id
  for id in "${CAT_IDS[@]}"; do
    if [[ -z "${1:-}" || ",${CAT_MENU[$id]}," == *",$1,"* ]]; then echo "$id"; fi
  done
}

# default_items -> the ids ticked on a new install.
default_items() {
  local id
  for id in "${CAT_IDS[@]}"; do if [[ "${CAT_DEFAULT[$id]}" == 1 ]]; then echo "$id"; fi; done
}

# item_on ID -> 0 when app ID is chosen (SOFTWARE_ITEMS, else the defaults).
item_on() {
  if [[ -n "${SOFTWARE_ITEMS+set}" ]]; then [[ " $SOFTWARE_ITEMS " == *" $1 "* ]]; else [[ "${CAT_DEFAULT[$1]:-}" == 1 ]]; fi
}

# chosen_items -> the chosen app ids, one per line, in catalog order.
chosen_items() {
  local id
  for id in "${CAT_IDS[@]}"; do if item_on "$id"; then echo "$id"; fi; done
}

# chosen_by_source KIND -> the packages (flatpak ids, script names, npm/uv packages, repo names) of chosen apps by
# KIND: rpm (everything dnf installs), terra, flatpak, script, npm, uvtool, repo (the vendor repo names).
chosen_by_source() {
  local id source pkgs
  while read -r id; do
    source=${CAT_SOURCE[$id]} pkgs=${CAT_PACKAGES[$id]}
    case "$1:$source" in
      terra:terra | flatpak:flatpak | npm:npm | uvtool:uvtool | noweak:noweak | rpm:dnf | rpm:rpmfusion | rpm:terra | rpm:repo:* | rpm:copr:*)
        tr ' ' '\n' <<<"$pkgs"
        ;;
      # npm and uv install the command-line agents, so they come along.
      rpm:npm) printf '%s\n' nodejs24 nodejs24-npm ;;
      rpm:uvtool) echo uv ;;
      script:script) echo "$pkgs" ;;
      repo:repo:*) echo "${source#repo:}" ;;
      copr:copr:*) echo "${source#copr:}" ;;
    esac
  done < <(chosen_items) | awk '!seen[$0]++'
}

# all_by_source KIND -> like chosen_by_source, for every app in the catalog (CI checks they all exist).
all_by_source() { SOFTWARE_ITEMS="${CAT_IDS[*]}" chosen_by_source "$1"; }

# default_for ROLE -> the chosen default app id for ROLE: DEFAULT_<ROLE>, else the first chosen app with that role.
default_for() {
  local var="DEFAULT_${1^^}" id
  if [[ -n "${!var:-}" ]] && item_on "${!var}"; then echo "${!var}"; return 0; fi
  while read -r id; do
    if [[ "${CAT_ROLE[$id]}" == "$1" ]]; then echo "$id"; return 0; fi
  done < <(chosen_items)
}
