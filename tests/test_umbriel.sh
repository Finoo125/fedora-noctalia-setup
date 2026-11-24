#!/usr/bin/env bash
# The Umbriel stub plus the repo defaults must load in Umbriel. Skipped where Umbriel isn't installed (CI).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh
source lib/user.sh

if ! have umbriel; then echo "skip: umbriel is not installed"; exit 0; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/umbriel"
umbriel_stub "$PWD" Windows-Cursors >"$tmp/umbriel/config.toml"
assert_true "Umbriel accepts the stub and the repo defaults" \
  sh -c "XDG_CONFIG_HOME='$tmp' umbriel config validate 2>&1 | grep -q '^config: ok'"
finish
