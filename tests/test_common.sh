#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

printf 'ID=fedora\nVERSION_ID=44\n' >"$tmp/f44"
printf 'ID=fedora\nVERSION_ID=45\n' >"$tmp/f45"
printf 'ID=fedora\nVERSION_ID=43\n' >"$tmp/f43"
printf 'ID=ubuntu\nVERSION_ID=24.04\n' >"$tmp/ubuntu"
assert_true  "Fedora 44 is accepted" fedora_version_ok "$tmp/f44"
assert_true  "Fedora 45 is accepted" fedora_version_ok "$tmp/f45"
assert_false "Fedora 43 is rejected" fedora_version_ok "$tmp/f43"
assert_false "Ubuntu is rejected"    fedora_version_ok "$tmp/ubuntu"

echo user >"$tmp/dest"; echo repo >"$tmp/src"
copy_once "$tmp/src" "$tmp/dest"
assert_eq "user" "$(cat "$tmp/dest")" "copy_once keeps an existing file"
copy_once "$tmp/src" "$tmp/new/dir/file"
assert_eq "repo" "$(cat "$tmp/new/dir/file")" "copy_once creates missing files and folders"

write_once "$tmp/dest" "generated"
assert_eq "user" "$(cat "$tmp/dest")" "write_once keeps an existing file"
write_once "$tmp/gen/file" "generated"
assert_eq "generated" "$(cat "$tmp/gen/file")" "write_once creates missing files"

STATE_DIR="$tmp/state"; CHOICES_FILE="$STATE_DIR/choices"
SOFTWARE_GROUPS="gaming dev"; save_choices
unset SOFTWARE_GROUPS; load_choices
assert_eq "gaming dev" "${SOFTWARE_GROUPS:-}" "saved groups load again"
SOFTWARE_GROUPS="printing"; load_choices
assert_eq "printing" "$SOFTWARE_GROUPS" "a group choice from the environment wins"
SOFTWARE_GROUPS=""; save_choices; unset SOFTWARE_GROUPS; load_choices
assert_false "no groups stays no groups" group_on gaming
rm -f "$CHOICES_FILE"; unset SOFTWARE_GROUPS
assert_true "without a choice every group is on" group_on flatpak

ANSWER_home_snapshots=yes
assert_true "an answer from the TUI is a yes" ask_once home-snapshots "Q?" n
ANSWER_artcraft=no
assert_false "an answer from the TUI is a no" ask_once artcraft "Q?" y
assert_true "the TUI's no is remembered for plain runs" test -f "$STATE_DIR/declined-artcraft"
ANSWER_artcraft=yes
assert_true "a later yes in the TUI wins over a remembered no" ask_once artcraft "Q?" n
assert_false "and forgets the no" test -f "$STATE_DIR/declined-artcraft"
unset ANSWER_home_snapshots ANSWER_artcraft

ASSUME=yes; assert_true  "ASSUME=yes answers yes" ask "Question?" n
ASSUME=no;  assert_false "ASSUME=no answers no"   ask "Question?" y

STATE_DIR="$tmp/state"
ASSUME=no;  assert_false "ask_once: a no is returned"        ask_once demo "Question?" y
ASSUME=yes; assert_false "ask_once: a remembered no is kept" ask_once demo "Question?" y
ASSUME=yes; assert_true  "ask_once: other keys still ask"    ask_once other "Question?" n
unset ASSUME

kernels=$'6.19.8-300.fc44.x86_64\n7.0.2-200.fc44.x86_64\n6.19.10-300.fc44.x86_64'
assert_eq "7.0.2-200.fc44.x86_64" "$(newest_version <<<"$kernels")" "newest kernel wins by version, not by text"
finish
