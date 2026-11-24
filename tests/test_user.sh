#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh
source lib/user.sh

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

repo=/home/u/.local/share/fedora-noctalia-setup
stub=$(umbriel_stub "$repo")
assert_true "stub includes the repo defaults" grep -qxF "files = [\"$repo/config/umbriel/defaults.toml\"]" <<<"$stub"
assert_true "stub keeps the monitor and color files optional" grep -qxF 'files = ["monitors.toml", "noctalia.toml"]' <<<"$stub"
assert_false "no cursor override on a new install" grep -qF 'input.cursor' <<<"$stub"
assert_true "a migrated cursor is kept" grep -qx 'theme = "Windows-Cursors"' <<<"$(umbriel_stub "$repo" Windows-Cursors)"
printf '[input.cursor]\ntheme = "Windows-Cursors"\nsize = 32\n\n[input.mouse]\ntheme = "nope"\n' >"$tmp/u.toml"
assert_eq "Windows-Cursors" "$(toml_value "$tmp/u.toml" input.cursor theme)" "toml_value reads a key from its section"
assert_eq "" "$(toml_value "$tmp/u.toml" input.touchpad theme)" "toml_value is empty for a missing section"
assert_eq "" "$(toml_value "$tmp/missing.toml" input.cursor theme)" "toml_value is empty for a missing file"

printf '# comment\n\nhttps://example.org/a/one.jpg\nhttps://example.org/b/two.png\n' >"$tmp/list.txt"
assert_eq $'https://example.org/a/one.jpg\nhttps://example.org/b/two.png' "$(wallpaper_urls "$tmp/list.txt")" "comments and blank lines are skipped"
assert_eq "$tmp/walls/one.jpg" "$(default_wallpaper "$tmp/list.txt" "$tmp/walls")" "first entry is the default"

curl_calls=0
curl() { # fake: -o FILE URL; fails for two.png
  curl_calls=$((curl_calls + 1))
  local out url
  while [[ $# -gt 0 ]]; do case "$1" in -o) out="$2"; shift 2 ;; -*) shift ;; *) url="$1"; shift ;; esac; done
  [[ "$url" == *two.png ]] && return 22
  echo data >"$out"
}
download_wallpapers "$tmp/list.txt" "$tmp/walls" 2>/dev/null
assert_true  "a working URL is downloaded"         test -f "$tmp/walls/one.jpg"
assert_false "a failing URL leaves no file"        test -e "$tmp/walls/two.png"
assert_false "a failing URL leaves no .part file"  test -e "$tmp/walls/two.png.part"
curl_calls=0
download_wallpapers "$tmp/list.txt" "$tmp/walls" 2>/dev/null
assert_eq "1" "$curl_calls" "re-run only retries what is missing"

local_toml=$(noctalia_local_toml /w/one.jpg /w)
assert_true "local toml sets the default wallpaper" grep -qF 'path = "/w/one.jpg"' <<<"$local_toml"
assert_true "wallpaper picker browses the download folder (not ~/Bilder on a German system)" grep -qF 'directory = "/w"' <<<"$local_toml"

# Desktop settings are applied once: later runs (every `update`) keep what the user changed.
mkdir -p "$tmp/fakebin"; log="$tmp/gs.log"; : >"$log"
printf '#!/bin/sh\necho dbus-run-session >>"%s"\nshift\nexec "$@"\n' "$log" >"$tmp/fakebin/dbus-run-session"
printf '#!/bin/sh\necho "gsettings $*" >>"%s"\n' "$log" >"$tmp/fakebin/gsettings"
chmod +x "$tmp/fakebin/dbus-run-session" "$tmp/fakebin/gsettings"
STATE_DIR="$tmp/state"
( unset DBUS_SESSION_BUS_ADDRESS; PATH="$tmp/fakebin:$PATH" set_desktop_settings )
assert_true "first run applies the icon theme"  grep -qF 'gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark' "$log"
assert_true "GTK apps use the Qt apps' font"   grep -qF 'gsettings set org.gnome.desktop.interface font-name Noto Sans 11' "$log"
assert_true "outside a session it starts its own bus" grep -qx 'dbus-run-session' "$log"
: >"$log"
( PATH="$tmp/fakebin:$PATH" set_desktop_settings )
assert_eq "" "$(cat "$log")" "second run leaves the user's settings alone"
rm -f "$STATE_DIR"/desktop-settings-applied; : >"$log"
( DBUS_SESSION_BUS_ADDRESS=unix:path=/fake PATH="$tmp/fakebin:$PATH" set_desktop_settings )
assert_false "inside a running session it uses that session's bus" grep -qx 'dbus-run-session' "$log"
defaults=config/umbriel/defaults.toml
assert_true "Qt and KDE apps use the kde platform theme" grep -qx 'QT_QPA_PLATFORMTHEME = "kde"' "$defaults"
assert_true "Umbriel sets Plasma's menu for Dolphin" grep -qx 'XDG_MENU_PREFIX = "plasma-"' "$defaults"
assert_true "Noctalia starts with Umbriel" grep -qx '  "noctalia",' "$defaults"
assert_false "no Hyprland tools in the Umbriel defaults" grep -qi 'hypr' "$defaults"
assert_true "Noctalia colors Umbriel" grep -qF '"umbriel"' config/noctalia/00-fedora-noctalia.toml
assert_false "no Hyprland template any more" grep -qF '"hyprland"' config/noctalia/00-fedora-noctalia.toml
assert_true "Noctalia writes the KDE color scheme" grep -qF '"kcolorscheme"' config/noctalia/00-fedora-noctalia.toml
assert_false "the plain qt template no longer competes with it" grep -qF '"qt"' config/noctalia/00-fedora-noctalia.toml

kde=$(kde_settings Windows-Cursors 24)
assert_true "KDE color scheme is the lower-case name Noctalia writes" grep -qxP 'kdeglobals\tGeneral\tColorScheme\tnoctalia' <<<"$kde"
assert_true "KDE cursor is the session's cursor" grep -qxP 'kcminputrc\tMouse\tcursorTheme\tWindows-Cursors' <<<"$kde"
assert_true "KWallet is off, gnome-keyring is the keyring" grep -qxP 'kwalletrc\tWallet\tEnabled\tfalse' <<<"$kde"
assert_eq "4" "$(awk -F'\t' '{print NF}' <<<"$kde" | sort -u)" "every KDE setting has file, group, key and value"
assert_true "new installs open folders in Luciole" grep -qx 'inode/directory=dev.noctalia.luciole.desktop' config/mimeapps.list

# Scripts are links into the repo; one you changed yourself stays.
cfg="$tmp/cfg"; mkdir -p "$cfg/umbriel/scripts"
cp config/umbriel/scripts/desks.sh "$cfg/umbriel/scripts/desks.sh"
echo 'my own' >"$cfg/umbriel/scripts/dock.sh"
link_umbriel_scripts "$PWD" "$cfg" 2>/dev/null
assert_eq "$PWD/config/umbriel/scripts/desks.sh" "$(readlink "$cfg/umbriel/scripts/desks.sh")" "an unchanged copy becomes a link"
assert_eq "my own" "$(cat "$cfg/umbriel/scripts/dock.sh")" "a changed script stays"
assert_false "a changed script is not replaced by a link" test -L "$cfg/umbriel/scripts/dock.sh"

# A fedora-hyprland machine with the Umbriel trial moves over once.
old="$tmp/old/.config"; REPO_DIR=/repo; STATE_DIR="$tmp/state-migrate"
mkdir -p "$old/noctalia" "$old/umbriel" "$old/xdg-desktop-portal" "$old/environment.d"
ln -s /home/u/.local/share/fedora-hyprland/config/noctalia/00-fedora-hyprland.toml "$old/noctalia/00-fedora-hyprland.toml"
echo x >"$old/noctalia/10-fedora-hyprland-local.toml"
echo '# Umbriel additions (not part of fedora-hyprland). Harmless under Hyprland.' >"$old/noctalia/20-umbriel.toml"
echo '# mine' >"$old/noctalia/40-mine.toml"
ln -s /home/u/.local/share/fedora-hyprland/config/noctalia/presets/waterfall.toml "$old/noctalia/30-preset.toml"
printf '# Umbriel config, translated from the fedora-hyprland Hyprland setup (x).\n[input.cursor]\ntheme = "Windows-Cursors"\n' >"$old/umbriel/config.toml"
printf '[preferred]\ndefault=umbriel;gtk\norg.freedesktop.impl.portal.Secret=kwallet\n' >"$old/xdg-desktop-portal/umbriel-portals.conf"
echo x >"$old/environment.d/60-fedora-hyprland-gpu.conf"
migrate_from_fedora_hyprland "$old"
assert_false "fedora-hyprland's Noctalia defaults are gone" test -e "$old/noctalia/00-fedora-hyprland.toml"
assert_false "its local file is gone"                      test -e "$old/noctalia/10-fedora-hyprland-local.toml"
assert_false "the trial's Noctalia additions are gone"     test -e "$old/noctalia/20-umbriel.toml"
assert_true  "your own Noctalia files stay"                test -e "$old/noctalia/40-mine.toml"
assert_eq "/repo/config/noctalia/presets/waterfall.toml" "$(readlink "$old/noctalia/30-preset.toml")" "the active look stays, from this repo"
assert_true  "the trial's Umbriel config is kept as a backup" grep -qF 'translated from' "$old/umbriel/config.toml.fedora-hyprland"
assert_true  "the new Umbriel config includes the defaults" grep -qF '/repo/config/umbriel/defaults.toml' "$old/umbriel/config.toml"
assert_true  "the cursor comes along" grep -qx 'theme = "Windows-Cursors"' "$old/umbriel/config.toml"
assert_true  "Flatpak passwords go to gnome-keyring" grep -qx 'org.freedesktop.impl.portal.Secret=gnome-keyring' "$old/xdg-desktop-portal/umbriel-portals.conf"
assert_false "the old GPU environment file is gone" test -e "$old/environment.d/60-fedora-hyprland-gpu.conf"
printf '# my own config\n' >"$old/umbriel/config.toml"
rm -f "$STATE_DIR/fedora-hyprland-migrated"
migrate_from_fedora_hyprland "$old"
assert_eq "# my own config" "$(cat "$old/umbriel/config.toml")" "a config you wrote yourself is never replaced"

# Looks: the preset names its wallpaper; without a running Noctalia only the link is set.
HOME="$tmp/home"; REPO_DIR="$PWD"; mkdir -p "$HOME"
assert_eq "$HOME/Pictures/Wallpapers/wallhaven-rq6j57.png" "$(preset_wallpaper config/noctalia/presets/waterfall.toml)" "a preset's wallpaper, ~ expanded"
assert_eq "" "$(preset_wallpaper "$tmp/missing.toml")" "no wallpaper for a missing preset"
( pgrep() { return 1; }; apply_preset night )
assert_eq "$PWD/config/noctalia/presets/night.toml" "$(readlink "$HOME/.config/noctalia/30-preset.toml")" "the chosen look is linked"
( pgrep() { return 1; }; apply_preset off )
assert_false "off removes the look" test -e "$HOME/.config/noctalia/30-preset.toml"

# State: answers and applied-once settings carry over from fedora-hyprland, once.
OLD_STATE_DIR="$tmp/st-old"; STATE_DIR="$tmp/st-new"; mkdir -p "$OLD_STATE_DIR"; : >"$OLD_STATE_DIR/declined-artcraft"
migrate_state
assert_true "a remembered no carries over" test -f "$STATE_DIR/declined-artcraft"
rm -f "$STATE_DIR/declined-artcraft"; migrate_state
assert_false "only the first run copies" test -f "$STATE_DIR/declined-artcraft"
finish
