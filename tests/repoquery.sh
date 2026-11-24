#!/usr/bin/env bash
# CI only (fedora:45 container, runs as root): adds the installer's repos with the real setup_repos, every vendor
# repo included, then checks that every dnf package and Flatpak any menu offers actually exists.
set -euo pipefail
cd "$(dirname "$0")/.."
dnf install -y sudo
source lib/common.sh
source lib/catalog.sh
source lib/drivers.sh
source lib/packages.sh
SOFTWARE_ITEMS="${CAT_IDS[*]}"
setup_repos

dnf repo list --enabled | grep -q '^terra ' || { echo "Terra repo is not enabled"; exit 1; }
if dnf repo list --enabled | terra_extra_repos | grep -q .; then echo "A Terra extra repo is still enabled"; exit 1; fi

mapfile -t wanted < <(all_dnf_packages)
# -y like install.sh: Terra signs its repo metadata (repo_gpgcheck=1), and importing that key needs a yes.
available=$(dnf repoquery -y --available --qf '%{name}.%{arch}\n' "${wanted[@]}")
missing=0
# Plain-text matching: names like gcc-c++ are not regexes. "name.arch" for i686 packages, else the name.
# shellcheck disable=SC2001 # strips the arch from every line
pkg_names=$(sed 's/\.[^.]*$//' <<<"$available")
for p in "${wanted[@]}"; do
  if [[ "$p" == *.i686 ]]; then list=$available; else list=$pkg_names; fi
  grep -qxF "$p" <<<"$list" || { echo "missing dnf package: $p"; missing=1; }
done
for app in $(all_by_source flatpak) "${FLATPAK_THEMES[@]}"; do
  flatpak remote-info flathub "$app" >/dev/null 2>&1 || { echo "missing flatpak: $app"; missing=1; }
done
# Agents installed with npm and uv must exist in their registries.
for pkg in $(all_by_source npm); do
  curl -fsS "https://registry.npmjs.org/$pkg/latest" >/dev/null || { echo "missing npm package: $pkg"; missing=1; }
done
for pkg in $(all_by_source uvtool); do
  curl -fsS "https://pypi.org/pypi/$pkg/json" >/dev/null || { echo "missing PyPI package: $pkg"; missing=1; }
done
exit $missing
