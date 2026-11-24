#!/usr/bin/env bash
# The documentation stays in step with the code: links resolve, every look and every default keybinding is listed.
# shellcheck disable=SC2016 # the backticks in the patterns are markdown, not commands
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh

for f in README.md docs/*.md; do
  while read -r link; do
    target="$(dirname "$f")/${link%%#*}"
    assert_true "$f links to an existing $link" test -e "$target"
  done < <(grep -oE '\]\([^)#:]+\.md(#[^)]*)?\)' "$f" | sed -E 's/^\]\(//; s/\)$//')
done

for p in config/noctalia/presets/*.toml; do
  name=$(basename "$p" .toml)
  assert_true "the looks guide lists $name" grep -q "^| \`$name\` |" docs/looks.md
done
while read -r name; do
  assert_true "the looks guide's $name exists" test -f "config/noctalia/presets/$name.toml"
done < <(sed -n 's/^| `\([a-z]*\)` |.*/\1/p' docs/looks.md)

while IFS='|' read -r id _ _ key _; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  assert_true "the keybindings guide shows $id on $key" grep -qF "| \`$key\` |" docs/keybindings.md
  assert_true "the keybindings guide names $id" grep -qF "| \`$id\` |" docs/keybindings.md
done <config/keybinds.tsv
finish
