#!/usr/bin/env bash
# The monitor scanner (EDID), the layout and its translation into each compositor, on made-up monitors.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source tests/edid.sh
source lib/common.sh
source lib/catalog.sh
source lib/monitors.sh

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
MONITORS_FILE="$tmp/monitors.conf"
printf 'HPN\tHP Inc.\nCSO\tCalifornia Institute of Technology\n' >"$tmp/pnp.ids"

# EDID: name and serial strings, else the product code and "Unknown", as wlroots and niri name monitors.
make_edid "$tmp/hp.bin" HPN 3B2F "HP X27i" CNC0123XYZ 60
assert_eq "HPN|HP X27i|CNC0123XYZ|600" "$(edid_info "$tmp/hp.bin")" "make, model, serial and width from the EDID"
assert_eq "HP Inc." "$(pnp_name HPN "$tmp/pnp.ids")" "the PNP id becomes the maker's name"
assert_eq "XYZ" "$(pnp_name XYZ "$tmp/pnp.ids")" "an unknown PNP id stays as it is"

# A laptop on a dock: two HP monitors and the panel.
drm="$tmp/drm"
fake_monitor "$drm" eDP-1 1920x1200 CSO 1506 "" "" 30
fake_monitor "$drm" DP-5 2560x1440 HPN 3A47 "HP E27q G5" CNK2210ABC 60
fake_monitor "$drm" DP-6 2560x1440 HPN 3B2F "HP X27i" CNC0123XYZ 60
mkdir -p "$drm/card1-HDMI-A-1"; echo disconnected >"$drm/card1-HDMI-A-1/status"
mon_scan "$drm" "$tmp/pnp.ids"
assert_eq "DP-5 DP-6 eDP-1" "${MON_IDS[*]}" "connected monitors only"
assert_eq "HP Inc. HP X27i CNC0123XYZ" "${MON_NAME[DP-6]}" "a monitor's full name"
assert_eq "California Institute of Technology 0x1506 Unknown" "${MON_NAME[eDP-1]}" "a panel without name or serial"
assert_eq "eDP-1" "$(mon_internal)" "the laptop panel is found"
assert_eq "1.5" "$(mon_auto_scale eDP-1)" "a dense laptop panel starts at 1.5"
assert_eq "1" "$(mon_auto_scale DP-6)" "a 27-inch 1440p monitor starts at 1"

mon_defaults
assert_eq "DP-5 DP-6 eDP-1" "${MON_ORDER[*]}" "externals first, the laptop on the right"
MON_ROT[DP-5]=270 MON_BELOW[eDP-1]=1
mon_layout
assert_eq "0,0" "${MON_X[DP-5]},${MON_Y[DP-5]}" "the portrait monitor on the left"
assert_eq "1440,0" "${MON_X[DP-6]},${MON_Y[DP-6]}" "a rotated monitor is as wide as it was tall"
assert_eq "1360,2560" "${MON_X[eDP-1]},${MON_Y[eDP-1]}" "the laptop centered below the row, scaled"
MON_ALIGN=bottom; mon_layout
assert_eq "1120" "${MON_Y[DP-6]}" "bottom alignment lines the row up at the bottom"
MON_ALIGN=top

# Saved by name, so the same monitors on other dock ports keep their place.
MON_LAPTOP_DOCKED=off; mon_save
rm -rf "$drm/card1-DP-5" "$drm/card1-DP-6"
fake_monitor "$drm" DP-7 2560x1440 HPN 3A47 "HP E27q G5" CNK2210ABC 60
fake_monitor "$drm" DP-8 2560x1440 HPN 3B2F "HP X27i" CNC0123XYZ 60
mon_scan "$drm" "$tmp/pnp.ids"; mon_load
assert_eq "DP-7 DP-8 eDP-1" "${MON_ORDER[*]}" "the order comes back on the new ports"
assert_eq "270" "${MON_ROT[DP-7]}" "and the rotation"
assert_eq "off" "$MON_LAPTOP_DOCKED" "and what the laptop does while docked"
fake_monitor "$drm" HDMI-A-1 1920x1080 HPN 1111 "Beamer" "" 200
mon_scan "$drm" "$tmp/pnp.ids"; mon_load
assert_eq "HDMI-A-1" "${MON_ORDER[3]}" "a monitor seen for the first time joins at the end"

# Each compositor's format.
rm -rf "$drm/card1-HDMI-A-1"; mon_scan "$drm" "$tmp/pnp.ids"; mon_load; mon_layout
umb=$(mon_umbriel) nir=$(mon_niri) man=$(mon_mango) hyp=$(mon_hypr)
assert_true "Umbriel: by name, turned"  grep -qF '[output."HP Inc. HP E27q G5 CNK2210ABC"]' <<<"$umb"
assert_true "Umbriel: transform 270"    grep -qx 'transform = "270"' <<<"$umb"
assert_true "Umbriel: the panel by connector" grep -qF '[output."eDP-1"]' <<<"$umb"
assert_true "niri: position"            grep -qx '    position x=1440 y=0' <<<"$nir"
assert_true "MangoWC: make, model, serial, rotation" grep -qF 'monitor_rule=make:^HP Inc\.$,model:^HP E27q G5$,serial:^CNK2210ABC$,x:0,y:0,scale:1,rr:3' <<<"$man"
assert_true "Hyprland: by description"  grep -qF 'output = "desc:HP Inc. HP X27i CNC0123XYZ"' <<<"$hyp"
assert_true "Hyprland: the panel goes off while docked" grep -qF 'hl.on("monitor.removed"' <<<"$hyp"
MON_LAPTOP_DOCKED=on
assert_false "Hyprland: no panel logic when it stays on" grep -qF 'monitor.removed' <<<"$(mon_hypr)"
MON_ON[eDP-1]=""
assert_true "a monitor that is off"     grep -qx 'monitor_rule=name:^eDP-1$,disable:1' <<<"$(mon_mango)"
assert_eq "1.5" "$(hypr_scale 1920 1200 1.5)" "Hyprland keeps a scale that divides the screen"
assert_eq "1.56667" "$(hypr_scale 2256 1504 1.5)" "and snaps one that doesn't (Framework 13)"

# dock-watch decides from the connectors and your choice.
mkdir -p "$tmp/cfg/fedora-noctalia-setup"
printf 'laptop-docked=off\n' >"$tmp/cfg/fedora-noctalia-setup/monitors.conf"
assert_eq "off" "$(XDG_CONFIG_HOME="$tmp/cfg" DOCK_WATCH_DRM="$drm" HYPRLAND_INSTANCE_SIGNATURE="" bin/dock-watch --once)" "docked and set to off: the panel goes off"
printf 'laptop-docked=on\n' >"$tmp/cfg/fedora-noctalia-setup/monitors.conf"
if ! grep -qs closed /proc/acpi/button/lid/*/state; then
  assert_eq "on" "$(XDG_CONFIG_HOME="$tmp/cfg" DOCK_WATCH_DRM="$drm" HYPRLAND_INSTANCE_SIGNATURE="" bin/dock-watch --once)" "docked and set to on: the panel stays on"
fi
rm -rf "$drm/card1-DP-7" "$drm/card1-DP-8"
printf 'laptop-docked=off\n' >"$tmp/cfg/fedora-noctalia-setup/monitors.conf"
assert_eq "on" "$(XDG_CONFIG_HOME="$tmp/cfg" DOCK_WATCH_DRM="$drm" HYPRLAND_INSTANCE_SIGNATURE="" bin/dock-watch --once)" "undocked: the panel is always on"
finish
