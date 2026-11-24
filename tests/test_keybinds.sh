#!/usr/bin/env bash
# The keybindings table, its translation into each compositor and your changes.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh
source lib/catalog.sh
source lib/keybinds.sh

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
KEYBINDS_FILE="$tmp/keybinds.conf"
kb_load
assert_eq "" "$(printf '%s\n' "${KB_IDS[@]}" | sort | uniq -d)" "every action id is unique"
assert_eq "" "$(for id in "${KB_IDS[@]}"; do echo "${KB_KEY[$id]}"; done | sort | uniq -d)" "no two actions share keys"
for id in "${KB_IDS[@]}"; do
  [[ "$(kb_normalize "${KB_DEFAULT[$id]}")" == "${KB_DEFAULT[$id]}" ]] || assert_eq "${KB_DEFAULT[$id]}" "$(kb_normalize "${KB_DEFAULT[$id]}")" "$id's default is spelled as the table spells keys"
done

assert_eq "Super+Shift+W" "$(kb_normalize super+shift+w)" "keys are case-insensitive"
assert_eq "Ctrl+Alt+F5" "$(kb_normalize ctrl+alt+f5)" "function keys"
assert_eq "Super+Period" "$(kb_normalize Win+period)" "Win means Super"
assert_false "an unknown key is refused" kb_normalize Super+Foo
assert_false "an unknown modifier is refused" kb_normalize Hyper+W
assert_false "a modifier twice is refused" kb_normalize Super+Super+W
assert_eq "browser" "$(kb_conflict files Super+W)" "a taken key is reported"

# Every action exists in every compositor (except where it can't: niri has no scratchpad, Hyprland no overview).
umb=$(kb_umbriel) nir=$(kb_niri) man=$(kb_mango) hyp=$(kb_hypr /repo)
assert_eq "${#KB_IDS[@]}" "$(grep -c '^"' <<<"$umb")" "Umbriel gets every action"
assert_eq "$((${#KB_IDS[@]} - 1))" "$(grep -c '{ .*; }' <<<"$nir")" "niri gets every action but the scratchpad"
assert_eq "${#KB_IDS[@]}" "$(grep -c '^bind' <<<"$man")" "MangoWC gets every action"
assert_eq "$((${#KB_IDS[@]} - 1))" "$(grep -c '^hl.bind' <<<"$hyp")" "Hyprland gets every action but the overview"
assert_true "Umbriel: modifiers as Mod"          grep -qF '"Mod+Shift+W" = { action = "spawn noctalia msg panel-toggle wallpaper", repeat = false }' <<<"$umb"
assert_true "niri: hardware keys on the lock screen" grep -qF 'XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "noctalia msg volume-up"; }' <<<"$nir"
assert_true "MangoWC: lower-case letters"        grep -qx 'bind=SUPER,w,spawn,open-default browser' <<<"$man"
assert_true "MangoWC: lock-screen keys use bindl" grep -qx 'bindl=NONE,XF86AudioMute,spawn,noctalia msg volume-mute' <<<"$man"
assert_true "Hyprland: digits by keycode"        grep -qF 'hl.bind("SUPER + code:10", function() desks.focus(1) end)' <<<"$hyp"
assert_true "Hyprland: Ctrl is CONTROL"          grep -qF 'hl.bind("CONTROL + SHIFT + Escape", run("xdg-terminal-exec btop"))' <<<"$hyp"

# Your changes: the file, then the TUI's; only differences are saved.
printf 'browser=Super+B\nnonsense=Super+N\n' >"$KEYBINDS_FILE"
kb_load
assert_eq "Super+B" "${KB_KEY[browser]}" "a saved change applies"
KEYBIND_OVERRIDES="browser=Super+W;files=Super+Shift+E"
kb_load
assert_eq "Super+W" "${KB_KEY[browser]}" "the TUI's choice wins over the file"
save_keybinds
assert_eq "files=Super+Shift+E" "$(grep -v '^#' "$KEYBINDS_FILE")" "only what differs from the defaults is saved"
unset KEYBIND_OVERRIDES
cfg="$tmp/cfg"
SOFTWARE_ITEMS="niri mango" write_keybinds "$cfg"
assert_true  "niri's bindings are written"   grep -q 'Mod+Shift+E' "$cfg/niri/keybinds.kdl"
assert_true  "MangoWC's bindings are written" test -f "$cfg/mango/keybinds.conf"
assert_false "compositors not chosen get none" test -e "$cfg/umbriel/keybinds.toml"
finish
