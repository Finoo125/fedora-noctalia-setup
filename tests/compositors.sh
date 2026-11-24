#!/usr/bin/env bash
# CI only (fedora:45 container, runs as root): installs every compositor the installer offers, writes the config
# stubs install.sh would write, and has each compositor validate them (Hyprland refuses root, so it runs as a user).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
dnf -y install dnf5-plugins >/dev/null
# shellcheck disable=SC2016 # $releasever is expanded by dnf
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release >/dev/null
dnf -y copr enable lionheartp/Hyprland >/dev/null
dnf -y install niri mangowm hyprland umbriel-nightly >/dev/null
source lib/common.sh
source lib/catalog.sh
source lib/keybinds.sh
source lib/monitors.sh
source lib/user.sh
source tests/edid.sh
fail=0
# A docked laptop's monitor layout too (portrait monitor, second monitor, the panel below and off while docked), so a
# monitor rule one of them rejects fails here.
drm=$(mktemp -d)
fake_monitor "$drm" eDP-1 1920x1200 CSO 1506 "" "" 30
fake_monitor "$drm" DP-5 2560x1440 HPN 3A47 "HP E27q G5" CNK2210ABC 60
fake_monitor "$drm" DP-6 2560x1440 HPN 3B2F "HP X27i" CNC0123XYZ 60
mon_scan "$drm"
mon_defaults
MON_ROT[DP-5]=270 MON_BELOW[eDP-1]=1 MON_LAPTOP_DOCKED=off
mon_layout
mkdir -p ~/.config/niri ~/.config/mango ~/.config/umbriel
mon_umbriel >~/.config/umbriel/monitors.toml
mon_niri >~/.config/niri/monitors.kdl
mon_mango >~/.config/mango/monitors.conf
mon_hypr >/tmp/monitors.lua
# The generated keybindings for every compositor too, so a key spelling one of them rejects fails here.
SOFTWARE_ITEMS="umbriel niri mango"
write_keybinds ~/.config
niri_stub "$PWD" us "" >~/.config/niri/config.kdl
mango_stub "$PWD" "$HOME" us "" >~/.config/mango/config.conf
umbriel_stub "$PWD" >~/.config/umbriel/config.toml
niri validate -c ~/.config/niri/config.kdl 2>&1 | grep -q 'config is valid' || { echo "niri: config invalid"; niri validate -c ~/.config/niri/config.kdl; fail=1; }
out=$(mango -c ~/.config/mango/config.conf -p 2>&1)
grep -q 'keybinds.conf' ~/.config/mango/keybinds.conf 2>/dev/null || true
if [[ -n "$out" ]]; then echo "mango: $out"; fail=1; fi
umbriel config validate 2>&1 | grep -q '^config: ok' || { echo "umbriel: config invalid"; umbriel config validate; fail=1; }
useradd -m tester
chmod -R a+rX "$PWD"
runuser -u tester -- bash -c "cd '$PWD' && source lib/common.sh && source lib/catalog.sh && source lib/keybinds.sh &&
  source lib/user.sh && mkdir -p ~/.config/hypr && hypr_stub '$PWD' >~/.config/hypr/hyprland.lua &&
  SOFTWARE_ITEMS=hyprland write_keybinds ~/.config && cp /tmp/monitors.lua ~/.config/hypr/monitors.lua &&
  export XDG_RUNTIME_DIR=/tmp/rt && mkdir -p /tmp/rt &&
  Hyprland --verify-config -c ~/.config/hypr/hyprland.lua 2>&1 | grep -qx 'config ok'" ||
  { echo "hyprland: config invalid"; fail=1; }
if ((fail == 0)); then echo "niri, MangoWC, Hyprland and Umbriel accept the configs, keybindings and monitor layout."; fi
exit $fail
