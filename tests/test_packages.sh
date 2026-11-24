#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh
source lib/catalog.sh
source lib/drivers.sh
source lib/packages.sh
unset SOFTWARE_ITEMS
# A machine without special hardware, so the results don't depend on the one running the tests.
hw_scan "" "" "" ""

repo_list='repo id                 repo name                          status
fedora                  Fedora 44 - x86_64                 enabled
terra                   Terra 44                           enabled
terra-extras            Terra 44 (Extras)                  enabled
terra-mesa              Terra 44 (Mesa)                    disabled
updates                 Fedora 44 - x86_64 - Updates       enabled'
assert_eq $'terra-extras\nterra-mesa' "$(terra_extra_repos <<<"$repo_list")" "only Terra's extra repos get disabled"

all=$(all_dnf_packages)
assert_true  "Umbriel is in the list"         grep -qx umbriel-nightly <<<"$all"
assert_false "Hyprland is gone"               grep -qx hyprland <<<"$all"
assert_false "no uwsm: Umbriel has its own systemd session" grep -qx uwsm <<<"$all"
assert_true  "Qt apps get the kde platform theme" grep -qx plasma-integration <<<"$all"
assert_true  "the Qt theme comes with Plasma, without weak deps" grep -qx plasma-integration < <(printf '%s\n' "${DNF_PLASMA[@]}")
assert_false "no COPR left"                   grep -q 'COPR_REPO=' lib/packages.sh
assert_true  "noctalia is in the list"        grep -qx noctalia <<<"$all"
assert_true  "NVIDIA packages are checked too" grep -qx akmod-nvidia <<<"$all"
assert_false "cliphist is not needed"         grep -qx cliphist <<<"$all"
assert_true  "dconf is installed so gsettings really saves" grep -qx dconf <<<"$all"
assert_false "no Qt5: it pulls in all of KF5 for no app" grep -qx qt5-qtwayland <<<"$all"
assert_eq "$(sort <<<"$all" | uniq -d)" "" "no package is listed twice"
assert_true  "the login unlocks the keyring"   grep -qx gnome-keyring-pam <<<"$all"
assert_true  "NAS files open in non-KDE apps"  grep -qx kio-fuse <<<"$all"
assert_true  "btrfs gets scrubbed"             grep -qx btrfsmaintenance <<<"$all"

allow=$(terra_allow)
for pkg in noctalia-greeter umbriel-nightly xdg-desktop-portal-umbriel-nightly luciole-nightly ghostty \
  signal-desktop heroic-games-launcher protonplus faugus-launcher mission-center helium-browser-bin zen-browser \
  gpu-screen-recorder; do
  assert_true "Terra allows $pkg" grep -q "\b$pkg\*" <<<"$allow"
done
assert_false "noctalia is Fedora's stable build, never Terra's" grep -q '\bnoctalia\*' <<<"$allow"
assert_false "Steam comes from RPM Fusion, never Terra" grep -q '\bsteam\*' <<<"$allow"
assert_false "Discord comes from RPM Fusion, never Terra" grep -q '\bdiscord\*' <<<"$allow"
flatpaks=$(all_by_source flatpak)
assert_false "Signal comes from Terra, not Flathub" grep -qx org.signal.Signal <<<"$flatpaks"
assert_false "Discord comes from RPM Fusion, not Flathub" grep -qx com.discordapp.Discord <<<"$flatpaks"

transaction=' Package                Arch   Version            Repository      Size
Installing:
 gparted               x86_64 1.7.0-3.fc44       fedora       6.8 MiB
Installing dependencies:
 gnome-shell           x86_64 50.6-1.fc44        updates     12.0 MiB
 gnome-shell-common    noarch 50.6-1.fc44        updates     16.4 KiB
 gdm                   x86_64 50.0-1.fc44        updates      5.1 MiB
Transaction Summary:
 Installing:         4 packages'
assert_eq $'gnome-shell\ngdm' "$(foreign_desktop_packages <<<"$transaction")" "a pulled-in GNOME Shell and GDM are caught"
assert_eq "" "$(grep -v 'gdm ' <<<"$transaction" | grep -v ' gnome-shell  ' | foreign_desktop_packages)" "gnome-shell-common alone is no desktop"
assert_eq "" "$(grep -vE 'gnome-shell |gdm ' <<<"$transaction" | foreign_desktop_packages)" "a clean transaction passes"
main=$(main_dnf_packages)
assert_true  "Luciole is a default file manager"            grep -qx luciole-nightly <<<"$main"
assert_true  "the COPR's Luciole is replaced"               grep -qx luciole-git < <(printf '%s\n' "${REPLACED_PACKAGES[@]}")
assert_true  "Hyprland is removed from an old install"      grep -qx hyprland < <(printf '%s\n' "${REPLACED_PACKAGES[@]}")
assert_true  "Dolphin is a default for Plasma and NAS shares" grep -qx dolphin <<<"$main"
assert_true  "KDE Partition Manager does the disks"         grep -qx kde-partitionmanager <<<"$main"
for pkg in Thunar gparted xfce-polkit gnome-disk-utility gnome-software papers qview vlc qt6ct file-roller; do
  assert_false "$pkg is not in a default install" grep -qx "$pkg" <<<"$main"
done
assert_true "a chosen VLC is installed, not removed as replaced" grep -qx vlc <<<"$(SOFTWARE_ITEMS="vlc"; main_dnf_packages)"
assert_false "Plasma is its own transaction, not in the main install" grep -qx plasma-workspace <<<"$main"
assert_true  "the Plasma fallback is checked in CI too"     grep -qx plasma-workspace <<<"$all"
assert_eq "" "$(grep -xF -f <(printf '%s\n' "${REPLACED_PACKAGES[@]}") <<<"$(main_dnf_packages)")" "a default install brings nothing that counts as replaced"
plasma_transaction=' Package                Arch   Version            Repository      Size
Installing:
 plasma-workspace      x86_64 6.7.5-1.fc44       updates     20.0 MiB
 kwin                  x86_64 6.7.5-1.fc44       updates     10.0 MiB
 plasma-login-manager  x86_64 6.7.5-1.fc44       updates      1.0 MiB
Transaction Summary:
 Installing:         3 packages'
assert_eq "plasma-login-manager" "$(foreign_desktop_packages "${FOREIGN_TO_PLASMA[@]}" <<<"$plasma_transaction")" \
  "the Plasma fallback may bring KWin, but no second login manager"
assert_eq $'plasma-workspace\nkwin\nplasma-login-manager' "$(foreign_desktop_packages <<<"$plasma_transaction")" \
  "the main install may bring no Plasma at all"

removal='Package                   Arch   Version          Repository      Size
Removing:
 Thunar                   x86_64 4.20.9-1.fc44    updates      5.0 MiB
 gnome-software           x86_64 50.4-1.fc44      updates     10.0 MiB
Removing dependent packages:
 gnome-software-fedora-langpacks noarch 50.4-1.fc44 updates    10.0 KiB

Transaction Summary:
 Removing:           3 packages'
assert_eq $'Thunar\ngnome-software\ngnome-software-fedora-langpacks' "$(removal_names <<<"$removal")" \
  "dependent packages count as removed too"
assert_false "NVIDIA drivers are not in the main install"   grep -qx akmod-nvidia <<<"$main"

# The menus: catalog defaults without a choice, exactly the chosen apps with one; the base is always there.
assert_true  "Steam is in a default install"          grep -qx steam <<<"$main"
assert_true  "Firefox is in a default install"        grep -qx firefox <<<"$main"
assert_false "Brave isn't ticked by default"          grep -qx brave-browser <<<"$main"
lean=$(SOFTWARE_ITEMS="brave printing"; main_dnf_packages)
assert_false "no Steam when it isn't chosen"          grep -qx steam <<<"$lean"
assert_false "no Docker when it isn't chosen"         grep -qx docker-ce <<<"$lean"
assert_true  "a chosen app's packages come along"     grep -qx cups <<<"$lean"
assert_true  "a vendor repo's app is installed"       grep -qx brave-browser <<<"$lean"
assert_eq "brave" "$(SOFTWARE_ITEMS="brave printing"; chosen_by_source repo)" "only the chosen vendor repos are added"
assert_true  "the desktop is always installed"        grep -qx umbriel-nightly <<<"$lean"
assert_true  "the base KDE tools are always installed" grep -qx ark <<<"$lean"
none=$(SOFTWARE_ITEMS=""; main_dnf_packages)
assert_false "an empty choice means no apps, not the defaults" grep -qx cups <<<"$none"
assert_eq "" "$(SOFTWARE_ITEMS=""; chosen_by_source flatpak)" "no Flatpaks without a choice of one"
assert_eq "$(sort <<<"$all" | uniq -d)" "" "menus don't repeat base packages"

# The catalog itself.
assert_eq "" "$(printf '%s\n' "${CAT_IDS[@]}" | sort | uniq -d)" "every app id is unique"
for id in "${CAT_IDS[@]}"; do
  case "${CAT_SOURCE[$id]}" in
    dnf | rpmfusion | terra | flatpak | script | npm | uvtool | repo:vscode | repo:docker | repo:brave | repo:vivaldi | repo:chrome | repo:edge) ;;
    *) assert_eq "a known source" "${CAT_SOURCE[$id]}" "$id has a known source" ;;
  esac
  for menu in ${CAT_MENU[$id]//,/ }; do
    printf '%s\n' "${CATEGORIES[@]%%|*}" | grep -qx "$menu" || assert_eq "a known menu" "$menu" "$id is in a known menu"
  done
done
for fn in $(all_by_source script); do assert_true "script app $fn exists" bash -c "source lib/common.sh; source lib/apps.sh; declare -F $fn"; done
assert_eq "ghostty" "$(default_for terminal)" "Ghostty is the default terminal"
assert_eq "firefox" "$(default_for browser)" "Firefox is the default browser"
assert_eq "luciole" "$(default_for files)" "Luciole is the default file manager"
assert_eq "kate" "$(default_for editor)" "Kate is the default editor"
assert_true  "ArtCraft is in Creative"               grep -qx artcraft <<<"$(catalog_ids creative)"
assert_true  "and in Office & text"                 grep -qx artcraft <<<"$(catalog_ids office)"
assert_true  "Ferdium is in Communication"           grep -qx ferdium <<<"$(catalog_ids chat)"
assert_true  "Betterbird is in Communication"        grep -qx betterbird <<<"$(catalog_ids chat)"
for id in retroarch dolphinemu pcsx2; do assert_false "no console emulator $id" grep -qx "$id" <<<"$(catalog_ids gaming)"; done
for id in cpp python node java rust go dotnet php ruby kotlin swift; do
  assert_true "Languages offers $id" grep -qx "$id" <<<"$(catalog_ids langs)"
done
for id in claude codex gemini copilot opencode goose aider; do
  assert_true "AI agents offers $id" grep -qx "$id" <<<"$(catalog_ids ai)"
done
npm_deps=$(SOFTWARE_ITEMS="gemini"; chosen_by_source rpm)
assert_true  "an npm agent brings Node.js and npm"   grep -qx nodejs24-npm <<<"$npm_deps"
assert_eq "@google/gemini-cli" "$(SOFTWARE_ITEMS="gemini"; chosen_by_source npm)" "npm agents are installed with npm"
assert_true  "a uv tool brings uv"                   grep -qx uv <<<"$(SOFTWARE_ITEMS="aider"; chosen_by_source rpm)"
assert_true  "driver packages are checked too"       grep -qx akmod-wl <<<"$all"
assert_true  "Terra allows the drivers it carries"   grep -q '\bxone\*' <<<"$allow"
amd_main=$(DRIVER_ITEMS="amd-graphics"; main_dnf_packages)
assert_true  "a chosen driver is installed"          grep -qx mesa-vulkan-drivers <<<"$amd_main"
assert_false "AMD's codecs come by swap, not in the main transaction" grep -qx mesa-va-drivers-freeworld <<<"$amd_main"
assert_eq "zen" "$(SOFTWARE_ITEMS="firefox zen"; DEFAULT_BROWSER=zen default_for browser)" "a chosen default wins"
assert_eq "firefox" "$(SOFTWARE_ITEMS="firefox"; DEFAULT_BROWSER=zen default_for browser)" "an unticked default falls back"

amd='03:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Navi 22 [Radeon RX 6700 XT] (rev c1)'
intel='00:02.0 VGA compatible controller: Intel Corporation Alder Lake-UP3 GT2 [Iris Xe Graphics] (rev 0c)'
nvidia='01:00.0 VGA compatible controller: NVIDIA Corporation AD107M [GeForce RTX 4060 Max-Q / Mobile] (rev a1)'
assert_true  "an AMD GPU is found"                  has_amd_gpu "$amd"
assert_true  "an AMD GPU next to NVIDIA is found"   has_amd_gpu "$amd"$'\n'"$nvidia"
assert_false "Intel graphics are not AMD"           has_amd_gpu "$intel"
assert_false "NVIDIA is not AMD"                    has_amd_gpu "$nvidia"

portals=config/xdg-desktop-portal/umbriel-portals.conf
assert_true "portals keep the package's umbriel;gtk default" grep -qx 'default=umbriel;gtk' "$portals"
assert_true "secrets go to gnome-keyring" grep -qx 'org.freedesktop.impl.portal.Secret=gnome-keyring' "$portals"
assert_true "file dialogs are Luciole's, GTK's as fallback" grep -qx 'org.freedesktop.impl.portal.FileChooser=luciole;gtk' "$portals"
assert_true "Plasma keeps passwords in gnome-keyring too" \
  grep -qx 'org.freedesktop.impl.portal.Secret=gnome-keyring' config/xdg-desktop-portal/kde-portals.conf
assert_true "gnome-keyring ships that portal" grep -qx gnome-keyring <<<"$(printf '%s\n' "${DNF_DESKTOP[@]}")"
finish
