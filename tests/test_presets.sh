#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
presets=(config/noctalia/presets/*.toml)
assert_true "the looks ship as presets" test ${#presets[@]} -ge 10
assert_true "the default look's wallpaper is downloaded by the installer" grep -qx 'https://w.wallhaven.cc/full/rq/wallhaven-rq6j57.png' config/wallpapers.txt
assert_eq "1" "$(grep -c 'w.wallhaven.cc' config/wallpapers.txt)" "the other looks' wallpapers are fetched on demand, not at install"
for f in "${presets[@]}"; do
  name=$(basename "$f" .toml)
  assert_true "$name is valid TOML" python3 -I -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$f"
  assert_true "$name says what it is" grep -q "^# Preset \"$name\": " "$f"
  assert_true "$name names its wallpaper" grep -q '^# wallpaper = ~/Pictures/Wallpapers/' "$f"
  assert_true "$name says where the wallpaper comes from" grep -qE '^# source = (https://|fedora-(day|night)$)' "$f"
  assert_false "$name keeps the template list of the base config" grep -q 'builtin_ids' "$f"
  assert_false "$name's widgets follow the screen that is on, not one connector" grep -q '^output = ' "$f"
done

# noctalia-preset against a fake noctalia that remembers the wallpaper, and a fake curl.
mkdir -p "$tmp/bin" "$tmp/home/.config/noctalia-presets"
cat >"$tmp/bin/noctalia" <<'FAKE'
#!/usr/bin/env bash
state="$HOME/wallpaper"
case "$2" in
  wallpaper-get) cat "$state" ;;
  wallpaper-set) echo "$3" >"$state" ;;
esac
FAKE
cat >"$tmp/bin/curl" <<'FAKE'
#!/usr/bin/env bash
while [[ $# -gt 0 ]]; do case "$1" in -o) out="$2"; shift 2 ;; *) shift ;; esac; done
echo image >"$out"
FAKE
chmod +x "$tmp/bin/noctalia" "$tmp/bin/curl"
echo /walls/old.jpg >"$tmp/home/wallpaper"
run() { HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" XDG_STATE_HOME="$tmp/home/.local/state" PATH="$tmp/bin:$PATH" bin/noctalia-preset "$@"; }
active="$tmp/home/.config/noctalia/30-preset.toml"

assert_true "the list shows waterfall" grep -q ' waterfall ' <<<"$(run)"
run waterfall >/dev/null
assert_eq "$PWD/config/noctalia/presets/waterfall.toml" "$(readlink "$active")" "waterfall links the repo's preset"
assert_eq "$tmp/home/Pictures/Wallpapers/wallhaven-rq6j57.png" "$(cat "$tmp/home/wallpaper")" "waterfall sets its wallpaper"
assert_true "the list marks waterfall active" grep -q '^\* waterfall ' <<<"$(run)"
run aurora >/dev/null 2>&1
assert_true "a look's wallpaper is downloaded the first time" test -f "$tmp/home/Pictures/Wallpapers/wallhaven-e83ve8.jpg"
assert_eq "$tmp/home/Pictures/Wallpapers/wallhaven-e83ve8.jpg" "$(cat "$tmp/home/wallpaper")" "and then set"
run fetch sakura 2>/dev/null
assert_true "fetch only downloads"            test -f "$tmp/home/Pictures/Wallpapers/wallhaven-gwdvxq.jpg"
assert_eq "$tmp/home/Pictures/Wallpapers/wallhaven-e83ve8.jpg" "$(cat "$tmp/home/wallpaper")" "fetch doesn't switch the look"
run off >/dev/null
assert_false "off removes the preset" test -e "$active"
assert_eq "/walls/old.jpg" "$(cat "$tmp/home/wallpaper")" "off brings back the wallpaper from before the first preset"
printf '# Preset "waterfall": mine.\n[theme]\nsource = "builtin"\n' >"$tmp/home/.config/noctalia-presets/waterfall.toml"
run waterfall >/dev/null
assert_eq "$tmp/home/.config/noctalia-presets/waterfall.toml" "$(readlink "$active")" "your own preset wins over the repo's"
assert_false "an unknown preset is refused" run nope
finish
