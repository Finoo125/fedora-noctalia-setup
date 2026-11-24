#!/usr/bin/env bash
# The TUI's pure parts and its screens, rendered at a fixed size without a terminal.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh
# shellcheck source=/dev/null
for lib in lib/*.sh; do [[ "$lib" == lib/common.sh ]] || source "$lib"; done

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
STATE_DIR="$tmp/state" LOG_FILE="$tmp/install.log" HOME="$tmp/home"
STEPS=("Language, keyboard|setup_locale" "Packages|install_packages" "NVIDIA|setup_nvidia")
TUI_GPU=none

assert_eq "truecolor" "$(tui_color_mode xterm-256color truecolor)" "COLORTERM=truecolor gets true color"
assert_eq "256" "$(tui_color_mode xterm-256color '')" "a 256-color terminal gets 256 colors"
assert_eq "16" "$(tui_color_mode linux '')" "the Linux console gets 16 colors"
assert_eq "16" "$(tui_hex256 000000)" "black is xterm color 16"
assert_eq "231" "$(tui_hex256 FFFFFF)" "white is xterm color 231"
assert_eq "222" "$(tui_hex256 E6B450)" "Ayu's accent maps into the color cube"

wrapped=$(tui_wrap 20 "one two three four five six seven eight nine ten")
assert_eq "0" "$(awk 'length > 20' <<<"$wrapped" | wc -l)" "wrapped lines fit the width"
assert_eq "one two three four five six seven eight nine ten" "$(tr '\n' ' ' <<<"$wrapped" | sed 's/ $//')" "wrapping keeps every word"
assert_eq "a*b" "$(tui_wrap 10 'a*b')" "wrapping doesn't expand globs"

tui_glyphs linux
assert_eq "+" "$G_DONE" "the Linux console gets ASCII marks"
tui_glyphs xterm-256color
assert_eq "✓" "$G_DONE" "terminals get symbols"

# Screens at 80x24, the smallest size the TUI draws.
tui_colors 16
tui_size() { TUI_H=24 TUI_W=80 TUI_C0=$((TUI_SB + 3)) TUI_CW=$((TUI_W - TUI_SB - 4)) TUI_R0=3 TUI_R1=$((TUI_H - 2)); }
tui_size
TUI_SYSTEM="Fedora Linux 45" TUI_LOCALE=en_US.UTF-8 TUI_LAYOUT=us TUI_TZ=UTC TUI_ROOT_FS=btrfs TUI_HOME_FS=btrfs
TUI_LAPTOP=1 TUI_GPU=none TUI_DM="" TUI_MIGRATE=""
unset SOFTWARE_ITEMS DRIVER_ITEMS
hw_scan "8086 46a8 0300" "04f3 0c7e ff," "HP" ""
tui_pages
tui_defaults
assert_true  "default apps start ticked"           test -n "${TUI_ON[firefox]}"
assert_false "other apps start unticked"           test -n "${TUI_ON[brave]}"
assert_eq "21" "${#TUI_WIZARD[@]}" "welcome, 14 menus, drivers, extras, look, review, install, done"
# shellcheck disable=SC2153 # set by tui_pages
assert_eq "menu:desktop" "${TUI_PAGES[1]}" "the compositors come first"
assert_eq "umbriel" "${TUI_DEFAULT[session]}" "Umbriel starts as the login session"
TUI_PAGE=1; TUI_SEL=0; KEY=space; tui_list_key
assert_true "the last compositor can't be unticked" test -n "${TUI_ON[umbriel]}"
TUI_SEL=2; KEY=d; tui_list_key
assert_eq "niri" "${TUI_DEFAULT[session]}" "D picks the login session"
TUI_SEL=0; KEY=space; tui_list_key
assert_false "with niri ticked, Umbriel can go"     test -n "${TUI_ON[umbriel]}"
KEY=space; tui_list_key; TUI_SEL=2; KEY=space; tui_list_key; TUI_DEFAULT[session]=umbriel
TUI_PAGE=2; TUI_SEL=0; KEY=space; tui_list_key; KEY=space; tui_list_key
assert_eq "ghostty" "${TUI_DEFAULT[terminal]}" "Ghostty starts as the default terminal"
assert_true "the scanned Intel driver starts ticked" test -n "${TUI_ON[intel-graphics]}"
assert_true "fingerprint login starts on where a reader was found" test -n "${TUI_ON[fingerprint]}"
assert_eq "waterfall" "$PRESET_CHOICE" "a new install starts with the waterfall look"

# shellcheck disable=SC2001 # a regex, not a fixed string
plain() { sed -e 's/\x1b\[[0-9;?]*[A-Za-z]/ /g' <<<"$TUI_BUF"; }
TUI_BTN=0; tui_screen_welcome
assert_true "welcome greets"                        grep -q "Welcome" <<<"$(plain)"
assert_false "no migration box on a new machine"    grep -q "fedora-hyprland found" <<<"$(plain)"
TUI_PAGE=4; TUI_SEL=0; TUI_TOP=0; tui_screen_list
assert_true "the browser menu lists Helium"         grep -q "Helium" <<<"$(plain)"
assert_true "and says where it comes from"          grep -q "Terra" <<<"$(plain)"
TUI_SEL=6; KEY=d; tui_list_key
assert_eq "vivaldi" "${TUI_DEFAULT[browser]}" "D makes the highlighted browser the default"
assert_true "and ticks it"                          test -n "${TUI_ON[vivaldi]}"
KEY=space; tui_list_key
assert_eq "firefox" "${TUI_DEFAULT[browser]}" "unticking the default falls back to the next ticked one"
TUI_SEL=0; KEY=space; tui_list_key
assert_eq "" "${TUI_DEFAULT[browser]}" "no browser ticked, no default"
KEY=space; tui_list_key
TUI_PAGE=12; TUI_SEL=19; TUI_TOP=0; tui_screen_list
assert_true "a long menu scrolls to the cursor"     grep -q "Julia" <<<"$(plain)"
TUI_PAGE=15; TUI_SEL=0; TUI_TOP=0; tui_screen_list
assert_true "the drivers page shows the scan"       grep -q "Intel graphics" <<<"$(plain)"
hw_scan "" "" "" ""; TUI_SEL=0; tui_screen_list
assert_true "a machine without extra drivers says so" grep -q "Nothing extra needed" <<<"$(plain)"
KEY=space; tui_list_key
assert_eq "15" "$TUI_PAGE" "keys on an empty drivers page don't fail"
hw_scan "8086 46a8 0300" "04f3 0c7e ff," "HP" ""

TUI_ON[steam]="" TUI_ON[docker]=""
TUI_PAGE=18; tui_plan
# shellcheck disable=SC2153 # set by tui_plan
assert_false "no Steam once it is unticked"         grep -qx steam < <(printf '%s\n' "${TUI_PKGS[@]}")
assert_false "no Docker repo once Docker is unticked" grep -qx docker < <(printf '%s\n' "${TUI_REPOS[@]}")
tui_screen_review
assert_true "the review counts the packages"        grep -q "${#TUI_PKGS[@]}" <<<"$(plain)"
assert_true "the review names the default browser"  grep -q "Firefox" <<<"$(plain)"

TUI_OFF_WHY=() TUI_ON[home-snapshots]=1 TUI_ON[grub-btrfs]="" TUI_ON[nvidia]="" TUI_ON[intel-graphics]=1
before=$FAILS
(
  tui_answers
  assert_eq "yes" "$ANSWER_home_snapshots" "a ticked extra becomes a yes"
  assert_eq "no" "$ANSWER_grub_btrfs" "an unticked extra becomes a no"
  assert_eq "firefox" "$DEFAULT_BROWSER" "the default browser goes to the install steps"
  assert_true "the chosen apps go to the install steps" grep -q "firefox" <<<"$SOFTWARE_ITEMS"
  assert_true "the chosen drivers go to the install steps" grep -q "intel-graphics" <<<"$DRIVER_ITEMS"
  assert_eq "no" "$NVIDIA" "an unticked NVIDIA driver is skipped"
  assert_eq "yes" "$ASSUME" "the steps never wait for an answer"
  [[ $FAILS -eq $before ]]
) || FAILS=$((FAILS + 1))

printf '%s\n' '==> Packages' '[ 98/157] Installing umbriel-nightly' >"$LOG_FILE"
TUI_STATE=("done" run skip) TUI_STEP=1 TUI_LOG_START=0
tui_screen_install
assert_true "the install shows dnf's counter"       grep -q "98 / 157" <<<"$(plain)"
assert_eq "2" "$TUI_DONE_STEPS" "done and skipped steps count as finished"
finish
