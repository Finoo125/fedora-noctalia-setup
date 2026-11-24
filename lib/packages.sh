# shellcheck shell=bash
# Package sources and package lists. Every function here is safe to run again.

# Terra brings only what Fedora and RPM Fusion don't package: the Noctalia parts without a Fedora package (Umbriel
# and Luciole have no releases upstream yet, so their nightly builds are the only ones), gpu-screen-recorder (Noctalia's
# screen recorder plugin) and the catalog's Terra apps.
TERRA_BASE=(noctalia-greeter umbriel-nightly xdg-desktop-portal-umbriel-nightly gpu-screen-recorder)
OLD_COPR="lionheartp/Hyprland"
OLD_COPR_ID="copr:copr.fedorainfracloud.org:lionheartp:Hyprland"

DNF_BASE=(dnf5-plugins flatpak pciutils jq)
# The desktop: Noctalia (shell, stable from Fedora) and its login screen. The compositors (Umbriel, Hyprland, niri,
# MangoWC) and the fallback desktops (Plasma, GNOME) are menus in lib/catalog.sh.
DNF_DESKTOP=(xdg-desktop-portal-gtk noctalia greetd noctalia-greeter
  pipewire pipewire-pulseaudio wireplumber bluez NetworkManager-wifi nm-connection-editor tuned-ppd upower
  gnome-keyring gnome-keyring-pam gcr dconf ddcutil bolt polkit qt6-qtwayland plasma-breeze-qt6 adw-gtk3-theme papirus-icon-theme
  google-noto-sans-fonts google-noto-color-emoji-fonts jetbrains-mono-fonts-all
  google-noto-sans-cjk-fonts liberation-fonts-all wl-clipboard grim slurp gpu-screen-recorder udiskie
  xdg-user-dirs xdg-utils xdg-terminal-exec libnotify playerctl brightnessctl)
# Apps every install gets; everything else is chosen in the menus (lib/catalog.sh). KDE apps read Noctalia's KDE
# color scheme (kdeglobals), so they match the desktop in Umbriel and in Plasma.
DNF_APPS=(ark kcalc kde-partitionmanager plasma-discover plasma-discover-flatpak ffmpegthumbs kdegraphics-thumbnailers
  kde-connect pavucontrol)
# Drives, network shares and devices in Dolphin: kio-extras (smb, nfs, sftp, mtp, afc for iPhones), kamera (cameras).
# kio-fuse gives smb://, mtp:// etc. a real path so non-KDE apps (mpv, ...) can open files there too.
# gvfs stays for the GTK apps (trash, recent files).
DNF_STORAGE=(kio-extras kio-fuse kamera gvfs
  udisks2 udisks2-btrfs ntfs-3g exfatprogs dosfstools udftools hfsplus-tools btrfs-progs xfsprogs
  cifs-utils nfs-utils samba-client fuse-sshfs libimobiledevice-utils ifuse unrar)
DNF_CLI=(git gh wget2-wget curl fastfetch btop bat eza fzf ripgrep fd-find zoxide unzip 7zip bash-completion plocate rsync ImageMagick)
# GPU drivers (Intel media driver, AMD codecs, NVIDIA) come from the driver scanner (lib/drivers.sh).
DNF_MEDIA=(libva-utils)
# AMD only: Fedora's mesa leaves out H.264/HEVC hardware decoding, RPM Fusion's build has it.
DNF_AMD=(mesa-va-drivers-freeworld)
DNF_SYSTEM=(fuse-libs avahi nss-mdns
  NetworkManager-openvpn-gnome NetworkManager-openconnect-gnome wireguard-tools fprintd fprintd-pam
  snapper btrfs-assistant btrfsmaintenance smartmontools libdnf5-plugin-actions fwupd thermald intel-lpmd inotify-tools)
DNF_NVIDIA=(akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-libs.i686 xorg-x11-drv-nvidia-power
  libva-nvidia-driver switcheroo-control)
DNF_SECUREBOOT=(kmodtool akmods mokutil openssl)
# plasma-integration is the "kde" Qt platform theme: Qt and KDE apps read Noctalia's colors, Breeze, Papirus and the
# fonts from kdeglobals. Only its weak dependencies would bring KWin and plasma-workspace, so it is installed without
# them, whether or not the Plasma fallback is chosen.
DNF_QT_THEME=(plasma-integration)
# Replaced by the KDE apps; removed once when an older install is migrated (see remove_replaced_apps), unless
# chosen in a menu (Thunar, VLC, Papers and GNOME Text Editor are choices now).
# Also the Hyprland stack of a fedora-hyprland install (it came from the lionheartp COPR, which is removed).
REPLACED_PACKAGES=(hyprland hyprland-guiutils hyprland-uwsm uwsm xdg-desktop-portal-hyprland hyprpicker hyprqt6engine nwg-look
  luciole-git Thunar thunar-archive-plugin thunar-volman tumbler ffmpegthumbnailer file-roller qview papers
  gnome-text-editor gnome-calculator gnome-software gnome-software-fedora-langpacks gnome-disk-utility gparted xfce-polkit
  vlc qt6ct gvfs-fuse gvfs-smb gvfs-nfs gvfs-mtp gvfs-afc gvfs-gphoto2 gvfs-archive)
# adw-gtk3 for GTK3 Flatpaks (DBeaver); without it they fall back to light Adwaita. Noctalia switches between the two.
FLATPAK_THEMES=(org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark)

# all_dnf_packages -> every dnf package the installer may install, one per line (CI checks they exist).
all_dnf_packages() {
  printf '%s\n' "${DNF_BASE[@]}" "${DNF_DESKTOP[@]}" "${DNF_APPS[@]}" "${DNF_STORAGE[@]}" "${DNF_CLI[@]}" "${DNF_MEDIA[@]}" \
    "${DNF_SYSTEM[@]}" "${DNF_NVIDIA[@]}" "${DNF_SECUREBOOT[@]}" "${DNF_AMD[@]}" "${DNF_QT_THEME[@]}" ffmpeg
  all_by_source rpm
  all_by_source noweak
  all_driver_packages rpm
}

# terra_allow -> Terra's includepkgs: the Noctalia parts and every catalog app from Terra (chosen or not, so a later
# choice works without touching the repo again).
terra_allow() {
  local -a pkgs=("${TERRA_BASE[@]}")
  mapfile -t -O "${#pkgs[@]}" pkgs < <(all_by_source terra; all_driver_packages terra)
  printf '%s*,' "${pkgs[@]}" | sed 's/,$//'
}

# main_dnf_packages -> the packages install_packages installs in one dnf transaction, one per line: the base plus
# the chosen apps.
main_dnf_packages() {
  printf '%s\n' "${DNF_DESKTOP[@]}" "${DNF_APPS[@]}" "${DNF_STORAGE[@]}" "${DNF_CLI[@]}" "${DNF_SYSTEM[@]}"
  { chosen_by_source rpm; chosen_driver_packages rpm; } | awk '!seen[$0]++'
}

# Other desktops' shells, sessions and login managers. A dependency that drags one in (as GParted once did
# with GNOME Shell) installs hundreds of MB the Umbriel setup never uses. The fallbacks come from their own menu.
FOREIGN_DESKTOP=(hyprland niri mangowm gnome-shell gnome-session mutter gdm kwin plasma-workspace sddm plasma-login-manager cinnamon
  xfce4-session mate-session-manager lightdm)
# The fallback desktops bring their own shell, but never a login manager or yet another desktop. GDM is the one
# exception: gnome-shell needs its library (gdm-libs is in the gdm package); setup_greeter keeps GDM switched off.
FOREIGN_TO_FALLBACK=(sddm plasma-login-manager lightdm cinnamon xfce4-session mate-session-manager)

# foreign_desktop_packages [NAME...]: stdin = `dnf install --assumeno` output -> the packages it would install
# that are in NAME... (default: FOREIGN_DESKTOP).
foreign_desktop_packages() {
  local -a names=("$@")
  ((${#names[@]})) || names=("${FOREIGN_DESKTOP[@]}")
  awk 'NF >= 5 {print $1}' | grep -xF -f <(printf '%s\n' "${names[@]}") || true
}

# removal_names: stdin = `dnf remove --assumeno` output -> the packages it would remove, one per line.
removal_names() {
  awk '/^Removing/ {on = 1; next} /^[A-Z]/ {on = 0} on && NF >= 5 {print $1}'
}

# has_amd_gpu LINES -> 0 when LINES (`lspci -d ::03xx`) contain an AMD/ATI GPU.
has_amd_gpu() { grep -qE '\b(AMD|ATI)\b' <<<"$1"; }

# terra_extra_repos: stdin = `dnf repo list --all` output -> Terra repo ids except the main "terra" repo.
terra_extra_repos() { awk '$1 ~ /^terra-/ {print $1}'; }

setup_repos() {
  local fedora repo
  fedora=$(rpm -E %fedora)
  sudo dnf install -y "${DNF_BASE[@]}"
  if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora}.noarch.rpm" \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora}.noarch.rpm"
  fi
  # COPRs only for what is chosen (Hyprland); fedora-hyprland's Hyprland COPR goes when Hyprland isn't.
  for repo in $(chosen_by_source copr); do sudo dnf copr enable -y "$repo"; done
  if ! chosen_by_source copr | grep -qx "$OLD_COPR" && dnf repo list --all 2>/dev/null | grep -q "^$OLD_COPR_ID "; then
    sudo dnf copr remove -y "$OLD_COPR"
  fi
  if ! rpm -q terra-release >/dev/null 2>&1; then
    # shellcheck disable=SC2016 # $releasever is expanded by dnf, not by the shell
    sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
  fi
  # Only TERRA_ALLOW comes from Terra; nothing else from it may replace a Fedora package (noctalia stays Fedora's).
  sudo dnf config-manager setopt "terra.includepkgs=$(terra_allow)"
  for repo in $(dnf repo list --all | terra_extra_repos); do
    sudo dnf config-manager setopt "$repo.enabled=0"
  done
  # Vendor repos (Docker, VS Code, Brave, ...) only for the apps chosen from them.
  for repo in $(chosen_by_source repo); do setup_vendor_repo "$repo"; done
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_packages() {
  local pkgs
  mapfile -t pkgs < <(main_dnf_packages)
  # fedora-hyprland had Luciole from the COPR; both builds own the same files, so swap before the big install.
  if rpm -q luciole-git >/dev/null 2>&1; then sudo dnf swap -y luciole-git luciole-nightly; fi
  sudo dnf install -y "${pkgs[@]}"
  # RPM Fusion's full ffmpeg replaces Fedora's ffmpeg-free; the multimedia group adds the matching GStreamer plugins.
  sudo dnf install -y --allowerasing ffmpeg
  sudo dnf group install -y multimedia --setopt=install_weak_deps=False --exclude=PackageKit-gstreamer-plugin
  sudo dnf install -y "${DNF_MEDIA[@]}"
  if driver_on amd-graphics && ! rpm -q "${DNF_AMD[@]}" >/dev/null 2>&1; then
    sudo dnf swap -y mesa-va-drivers "${DNF_AMD[@]}"
  fi
  # Minimal Install leaves out the firmware for Wi-Fi, Bluetooth and audio chips (e.g. Intel iwlwifi).
  sudo dnf group install -y hardware-support
  # The Qt theme and the chosen fallback desktops, without weak dependencies (no login manager, no extra apps).
  local -a fallback
  mapfile -t fallback < <(chosen_by_source noweak)
  sudo dnf install -y --setopt=install_weak_deps=False "${DNF_QT_THEME[@]}" "${fallback[@]}"
  remove_replaced_apps
}

# remove_replaced_apps: once per machine, removes what an older install had where something else took over: GTK apps
# replaced by KDE apps, and fedora-hyprland's Hyprland stack.
# Skipped (with a warning) if dnf would also remove anything else, so nothing you added yourself disappears.
remove_replaced_apps() {
  local marker="$STATE_DIR/replaced-packages-removed" transaction extra
  local -a installed=()
  [[ -f "$marker" ]] && return 0
  # `|| true`: none installed is fine, and the process substitution would otherwise fire install.sh's ERR trap.
  # Apps chosen in a menu stay, even when an older install treated them as replaced.
  mapfile -t installed < <(rpm -q --qf '%{NAME}\n' "${REPLACED_PACKAGES[@]}" 2>/dev/null | grep -v ' ' |
    grep -vxF -f <(main_dnf_packages) || true)
  if ((${#installed[@]})); then
    transaction=$(LC_ALL=C sudo dnf remove --assumeno --noautoremove "${installed[@]}" 2>&1 || true)
    extra=$(removal_names <<<"$transaction" | grep -vxF -f <(printf '%s\n' "${installed[@]}") || true)
    if [[ -n "$extra" ]]; then
      warn "Not removing the replaced apps: dnf would also remove $(tr '\n' ' ' <<<"$extra")"
      return 0
    fi
    sudo dnf remove -y --noautoremove "${installed[@]}"
  fi
  mkdir -p "$STATE_DIR"
  : >"$marker"
}

install_flatpaks() {
  local -a apps
  mapfile -t apps < <(chosen_by_source flatpak)
  sudo flatpak install -y --noninteractive flathub "${apps[@]}" "${FLATPAK_THEMES[@]}"
  # Cursors (and icons) installed for your user live in ~/.local/share/icons, which Flatpaks can't see otherwise.
  # Noctalia's colors: GTK apps read them from gtk-3.0/gtk-4.0, Qt apps from kdeglobals through the KDE runtime's
  # platform theme, like the desktop itself (without it Qt Flatpaks get Qt's plain look).
  flatpak override --user --filesystem=xdg-data/icons:ro \
    --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/kdeglobals:ro \
    --env=QT_QPA_PLATFORMTHEME=kde
}
