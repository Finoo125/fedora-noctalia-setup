# shellcheck shell=bash
# Per-user configuration: config layering, Umbriel config, wallpapers, GTK/Qt/KDE settings.

WALL_DIR="$HOME/Pictures/Wallpapers"
UMBRIEL_SCRIPTS=(desks.sh dock.sh)

# umbriel_stub REPO [CURSOR] -> ~/.config/umbriel/config.toml (written once, then it's yours). Umbriel applies the
# included defaults first and this file last, so whatever is set here wins.
umbriel_stub() {
  cat <<EOF
# Your Umbriel config. fedora-noctalia-setup created it once and never overwrites it.
# The defaults live in $1/config/umbriel/defaults.toml and update with the \`update\` command.
# Tables merge key by key; a list you set here (like general.autostart) replaces the default list.

[include]
files = ["$1/config/umbriel/defaults.toml"]

[include.optional]
files = ["monitors.toml", "noctalia.toml"]

# Your own changes go below this line.
EOF
  if [[ -n "${2:-}" ]]; then printf '\n[input.cursor]\ntheme = "%s"\n' "$2"; fi
}

# toml_value FILE SECTION KEY -> the quoted string value of KEY in [SECTION], empty when missing.
toml_value() {
  awk -v sec="[$2]" -v key="$3" '
    /^[[:space:]]*\[/ { insec = ($1 == sec) }
    insec && $1 == key && $2 == "=" { v = $3; gsub(/"/, "", v); print v; exit }' "$1" 2>/dev/null
}

# link_umbriel_scripts REPO CONFIG_DIR: ~/.config/umbriel/scripts/* point into the repo, so `update` updates them.
# A script you changed yourself (not a link, different content) stays.
link_umbriel_scripts() {
  local name src dest
  mkdir -p "$2/umbriel/scripts"
  for name in "${UMBRIEL_SCRIPTS[@]}"; do
    src="$1/config/umbriel/scripts/$name" dest="$2/umbriel/scripts/$name"
    if [[ -e "$dest" && ! -L "$dest" ]] && ! cmp -s "$src" "$dest"; then
      warn "Keeping your own $dest; the repo's version is $src."
      continue
    fi
    ln -sfn "$src" "$dest"
  done
}

# noctalia_local_toml WALLPAPER DIR -> per-user values Noctalia needs as absolute paths.
# The picker folder is pinned because XDG's Pictures folder is localized (e.g. ~/Bilder on a German system).
noctalia_local_toml() {
  cat <<EOF
# Written by fedora-noctalia-setup on every install.sh run. The Settings GUI overrides it.
[wallpaper]
directory = "$2"

[wallpaper.default]
path = "$1"
EOF
}

# kde_settings CURSOR SIZE -> tab-separated "FILE GROUP KEY VALUE" lines for kwriteconfig6: the same look in KDE apps
# and in the Plasma fallback. ColorScheme is "noctalia" in lower case, the name Noctalia's template writes; a differently
# spelled copy would stop following theme changes.
kde_settings() {
  printf '%s\t%s\t%s\t%s\n' \
    kdeglobals General ColorScheme noctalia \
    kdeglobals General font "Noto Sans,11" \
    kdeglobals General fixed "JetBrains Mono,11" \
    kdeglobals Icons Theme Papirus-Dark \
    kdeglobals KDE widgetStyle Breeze \
    kdeglobals KDE SingleClick false \
    kcminputrc Mouse cursorTheme "$1" \
    kcminputrc Mouse cursorSize "$2" \
    kwalletrc Wallet Enabled false \
    kwalletrc Wallet "First Use" false
}

# Applied once, like set_desktop_settings: later changes in Plasma's System Settings stay. KWallet stays off, so
# gnome-keyring is the only keyring in both sessions. The cursor is the one the Umbriel session uses.
set_kde_settings() {
  local marker="$STATE_DIR/kde-settings-applied" conf="$HOME/.config/umbriel/config.toml" file group key value cursor
  [[ -f "$marker" ]] && return 0
  have kwriteconfig6 || { warn "kwriteconfig6 is missing, so KDE apps keep their default look."; return 0; }
  cursor=$(toml_value "$conf" input.cursor theme)
  while IFS=$'\t' read -r file group key value; do
    kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value"
  done < <(kde_settings "${cursor:-Classic-pointer}" 32)
  mkdir -p "$STATE_DIR"
  : >"$marker"
}

# preset_wallpaper FILE -> the wallpaper a preset names on its "# wallpaper = PATH" line, ~ expanded.
preset_wallpaper() {
  local path
  path=$(sed -n 's/^# wallpaper = //p' "$1" 2>/dev/null | head -1)
  [[ -n "$path" ]] && echo "${path/#\~/$HOME}"
}

# apply_preset NAME: the look chosen in the TUI ("off" = none). In a running Noctalia, noctalia-preset switches it
# live; otherwise (first install) only the link is set and the preset's wallpaper becomes the default.
apply_preset() {
  local active="$HOME/.config/noctalia/30-preset.toml" file="$REPO_DIR/config/noctalia/presets/$1.toml"
  if pgrep -x noctalia >/dev/null 2>&1; then
    "$REPO_DIR/bin/noctalia-preset" "$1" >/dev/null || warn "Could not switch the look to $1."
    return 0
  fi
  if [[ "$1" == off ]]; then rm -f "$active"; return 0; fi
  [[ -f "$file" ]] || { warn "There is no look named $1."; return 0; }
  mkdir -p "$(dirname "$active")"
  ln -sfn "$file" "$active"
}

wallpaper_urls() { grep -vE '^[[:space:]]*(#|$)' "$1"; }
default_wallpaper() { echo "$2/$(basename "$(wallpaper_urls "$1" | head -1)")"; }

# download_wallpapers LIST DIR: fetch missing wallpapers; a failed download warns and continues.
download_wallpapers() {
  local url file
  mkdir -p "$2"
  while read -r url; do
    file="$2/$(basename "$url")"
    [[ -f "$file" ]] && continue
    if curl -fsSL --retry 2 -o "$file.part" "$url"; then
      mv "$file.part" "$file"
    else
      rm -f "$file.part"
      warn "Could not download wallpaper $url"
    fi
  done < <(wallpaper_urls "$1")
}

# Applied once: later runs (every `update`) keep what the user changed in Noctalia.
set_desktop_settings() {
  local marker="$STATE_DIR/desktop-settings-applied" settings='
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    gsettings set org.gnome.desktop.interface font-name "Noto Sans 11"
    gsettings set org.gnome.desktop.interface document-font-name "Noto Sans 11"
    gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 11"
    gsettings set org.gnome.desktop.interface cursor-theme Classic-pointer
    gsettings set org.gnome.desktop.interface cursor-size 32'
  [[ -f "$marker" ]] && return 0
  if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    sh -c "$settings"
  else
    dbus-run-session -- sh -c "$settings" # from a TTY there is no session bus yet
  fi
  mkdir -p "$STATE_DIR"
  : >"$marker"
}

setup_user() {
  local item wall list="$REPO_DIR/config/wallpapers.txt"
  xdg-user-dirs-update
  mkdir -p "$HOME/.config/noctalia"
  ln -sfn "$REPO_DIR/config/noctalia/00-fedora-noctalia.toml" "$HOME/.config/noctalia/00-fedora-noctalia.toml"
  migrate_from_fedora_hyprland "$HOME/.config"
  for item in ghostty/config kitty/kitty.conf gtk-3.0/settings.ini gtk-4.0/settings.ini mimeapps.list \
    xdg-desktop-portal/umbriel-portals.conf xdg-desktop-portal/kde-portals.conf; do
    copy_once "$REPO_DIR/config/$item" "$HOME/.config/$item"
  done
  write_once "$HOME/.config/umbriel/config.toml" "$(umbriel_stub "$REPO_DIR")"
  link_umbriel_scripts "$REPO_DIR" "$HOME/.config"
  # Noctalia's btop template only switches the theme in an existing btop.conf; btop fills in the rest itself.
  write_once "$HOME/.config/btop/btop.conf" 'color_theme = "noctalia"'
  download_wallpapers "$list" "$WALL_DIR"
  wall=$(default_wallpaper "$list" "$WALL_DIR")
  if [[ -n "${PRESET_CHOICE:-}" && "$PRESET_CHOICE" != off ]]; then
    wall=$(preset_wallpaper "$REPO_DIR/config/noctalia/presets/$PRESET_CHOICE.toml" || echo "$wall")
  fi
  noctalia_local_toml "$wall" "$WALL_DIR" >"$HOME/.config/noctalia/10-fedora-noctalia-local.toml"
  set_desktop_settings
  set_kde_settings
  # Dolphin's "Open with" list and the KDE apps' file associations come from this cache.
  XDG_MENU_PREFIX=plasma- kbuildsycoca6 >/dev/null 2>&1 || warn "kbuildsycoca6 failed, so Dolphin's \"Open with\" may stay empty until you log in again."
  # Native host for the Pywalfox extension, so Firefox follows Noctalia's colors.
  noctalia firefox-theme install >/dev/null || warn "Could not set up Firefox theming (noctalia firefox-theme install)."
  # Noctalia writes to ~/.mozilla; Firefox 147+ reads ~/.config/mozilla on new installs.
  mkdir -p "$HOME/.config/mozilla/native-messaging-hosts"
  ln -sfn "$HOME/.mozilla/native-messaging-hosts/pywalfox.json" "$HOME/.config/mozilla/native-messaging-hosts/pywalfox.json"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$REPO_DIR/bin/update" "$HOME/.local/bin/update"
  ln -sfn "$REPO_DIR/bin/noctalia-preset" "$HOME/.local/bin/noctalia-preset"
  if [[ -n "${PRESET_CHOICE:-}" ]]; then apply_preset "$PRESET_CHOICE"; fi
}

# migrate_from_fedora_hyprland CONFIG_DIR: once, moves a fedora-hyprland machine over. Only what fedora-hyprland (or
# the Umbriel trial next to it) created is touched; ~/.config/hypr and ~/.config/uwsm stay for reference.
migrate_from_fedora_hyprland() {
  local marker="$STATE_DIR/fedora-hyprland-migrated" noctalia="$1/noctalia" umbriel="$1/umbriel/config.toml"
  local preset cursor
  [[ -f "$marker" ]] && return 0
  # Noctalia layers: fedora-hyprland's defaults would compete with ours (its template list still has "hyprland").
  if [[ -L "$noctalia/00-fedora-hyprland.toml" ]]; then rm -f "$noctalia/00-fedora-hyprland.toml"; fi
  rm -f "$noctalia/10-fedora-hyprland-local.toml"
  if grep -qs 'not part of fedora-hyprland' "$noctalia/20-umbriel.toml"; then rm -f "$noctalia/20-umbriel.toml"; fi
  # The active look keeps its name, now from this repo's presets.
  preset=$(readlink "$noctalia/30-preset.toml" 2>/dev/null || true)
  if [[ "$preset" == */fedora-hyprland/config/noctalia/presets/*.toml ]]; then
    ln -sfn "$REPO_DIR/config/noctalia/presets/$(basename "$preset")" "$noctalia/30-preset.toml"
  fi
  # The trial's full Umbriel config becomes the layered one; your cursor comes along, the old file stays as a backup.
  if grep -qs 'translated from the fedora-hyprland Hyprland setup' "$umbriel"; then
    cursor=$(toml_value "$umbriel" input.cursor theme)
    mv "$umbriel" "$umbriel.fedora-hyprland"
    umbriel_stub "$REPO_DIR" "$cursor" >"$umbriel"
  fi
  # Passwords stay in gnome-keyring (the trial's portal file pointed Flatpaks at KWallet).
  if [[ -f "$1/xdg-desktop-portal/umbriel-portals.conf" ]]; then
    sed -i 's/^org\.freedesktop\.impl\.portal\.Secret=kwallet$/org.freedesktop.impl.portal.Secret=gnome-keyring/' \
      "$1/xdg-desktop-portal/umbriel-portals.conf"
  fi
  rm -f "$1/environment.d/60-fedora-hyprland-gpu.conf"
  mkdir -p "$STATE_DIR"
  : >"$marker"
}
