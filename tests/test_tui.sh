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
unset SOFTWARE_GROUPS
tui_defaults
assert_true  "groups start on"                     test -n "${TUI_ON[gaming]}"
assert_eq "no NVIDIA card" "${TUI_OFF_WHY[nvidia]}" "NVIDIA can't be ticked without a card"
assert_eq "waterfall" "$PRESET_CHOICE" "a new install starts with the waterfall look"

# shellcheck disable=SC2001 # a regex, not a fixed string
plain() { sed -e 's/\x1b\[[0-9;?]*[A-Za-z]/ /g' <<<"$TUI_BUF"; }
TUI_BTN=0; tui_screen_welcome
assert_true "welcome greets"                        grep -q "Welcome" <<<"$(plain)"
assert_false "no migration box on a new machine"    grep -q "fedora-hyprland found" <<<"$(plain)"
TUI_SEL=$(tui_next_opt 0 1)
assert_eq "4" "$TUI_SEL" "the cursor starts on the first group, not a heading"
assert_eq "4" "$(tui_next_opt 4 -1)" "it can't move above the first option"
tui_screen_software
assert_true "the software screen lists Gaming"      grep -q "Gaming" <<<"$(plain)"

TUI_ON[gaming]="" TUI_ON[dev]=""
tui_plan
assert_eq "printing flatpak" "$SOFTWARE_GROUPS" "the review installs the ticked groups"
assert_false "no Steam once gaming is unticked"     grep -qx steam < <(printf '%s\n' "${TUI_PKGS[@]}")
tui_screen_review
assert_true "the review counts the packages"        grep -q "${#TUI_PKGS[@]}" <<<"$(plain)"

TUI_OFF_WHY=() TUI_ON[home-snapshots]=1 TUI_ON[artcraft]="" TUI_ON[nvidia]=""
(
  tui_answers
  assert_eq "yes" "$ANSWER_home_snapshots" "a ticked extra becomes a yes"
  assert_eq "no" "$ANSWER_artcraft" "an unticked extra becomes a no"
  assert_eq "no" "$NVIDIA" "an unticked NVIDIA driver is skipped"
  assert_eq "yes" "$ASSUME" "the steps never wait for an answer"
  [[ $FAILS -eq 0 ]]
) || FAILS=$((FAILS + 1))

printf '%s\n' '==> Packages' '[ 98/157] Installing umbriel-nightly' >"$LOG_FILE"
TUI_STATE=("done" run skip) TUI_STEP=1 TUI_LOG_START=0
tui_screen_install
assert_true "the install shows dnf's counter"       grep -q "98 / 157" <<<"$(plain)"
assert_eq "2" "$TUI_DONE_STEPS" "done and skipped steps count as finished"
finish
