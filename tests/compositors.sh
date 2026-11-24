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
source lib/user.sh
fail=0
mkdir -p ~/.config/niri ~/.config/mango ~/.config/umbriel
niri_stub "$PWD" us "" >~/.config/niri/config.kdl
mango_stub "$PWD" "$HOME" us "" >~/.config/mango/config.conf
umbriel_stub "$PWD" >~/.config/umbriel/config.toml
niri validate -c ~/.config/niri/config.kdl 2>&1 | grep -q 'config is valid' || { echo "niri: config invalid"; niri validate -c ~/.config/niri/config.kdl; fail=1; }
out=$(mango -c ~/.config/mango/config.conf -p 2>&1)
if [[ -n "$out" ]]; then echo "mango: $out"; fail=1; fi
umbriel config validate 2>&1 | grep -q '^config: ok' || { echo "umbriel: config invalid"; umbriel config validate; fail=1; }
useradd -m tester
chmod -R a+rX "$PWD"
runuser -u tester -- bash -c "cd '$PWD' && source lib/common.sh && source lib/user.sh && mkdir -p ~/.config/hypr &&
  hypr_stub '$PWD' >~/.config/hypr/hyprland.lua && export XDG_RUNTIME_DIR=/tmp/rt && mkdir -p /tmp/rt &&
  Hyprland --verify-config -c ~/.config/hypr/hyprland.lua 2>&1 | grep -qx 'config ok'" ||
  { echo "hyprland: config invalid"; fail=1; }
if ((fail == 0)); then echo "niri, MangoWC, Hyprland and Umbriel accept the configs."; fi
exit $fail
