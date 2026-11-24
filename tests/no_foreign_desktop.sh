#!/usr/bin/env bash
# CI only, right after tests/repoquery.sh in the same fedora:45 container (its repos are already set up):
# resolves install_packages' dnf transaction without installing it and fails if a dependency would pull in
# another desktop (GNOME Shell, KDE, GDM, ...), and that the fallback desktops bring no login manager.
set -euo pipefail
cd "$(dirname "$0")/.."
source lib/common.sh
source lib/catalog.sh
source lib/drivers.sh
source lib/packages.sh

# check NAME TRANSACTION FOREIGN...: fails when TRANSACTION would install one of FOREIGN.
check() {
  local name="$1" transaction="$2" foreign
  shift 2
  grep -q '^Transaction Summary' <<<"$transaction" || { echo "$transaction"; echo "dnf could not resolve the $name"; exit 1; }
  foreign=$(foreign_desktop_packages "$@" <<<"$transaction")
  if [[ -n "$foreign" ]]; then
    echo "The $name would pull in another desktop or login manager: $(tr '\n' ' ' <<<"$foreign")"
    echo "Find the culprit with: dnf repoquery --whatrequires <package> --recursive"
    exit 1
  fi
  echo "The $name pulls in no other desktop ($(wc -l <<<"$transaction") lines of dnf transaction checked)."
}

mapfile -t pkgs < <(main_dnf_packages)
check "main install" "$(LC_ALL=C dnf install -y --assumeno "${pkgs[@]}" 2>&1 || true)" "${FOREIGN_DESKTOP[@]}"
# The Qt theme and the fallback desktops (both, the worst case) are their own transaction, without weak dependencies.
mapfile -t fallback < <(SOFTWARE_ITEMS="plasma gnome"; chosen_by_source noweak)
check "Qt theme and fallback desktops" "$(LC_ALL=C dnf install -y --assumeno --setopt=install_weak_deps=False "${pkgs[@]}" \
  "${DNF_QT_THEME[@]}" "${fallback[@]}" 2>&1 || true)" "${FOREIGN_TO_FALLBACK[@]}"
