#!/usr/bin/env bash
# fedora-noctalia-setup: turns a fresh Fedora 44 Minimal install into a Noctalia desktop: Umbriel, Noctalia v5,
# the Noctalia login screen and Luciole, with KDE Plasma as a fallback session.
# Usage (as your normal user; re-running is safe and is how updates are applied):
#   ./install.sh            the full-screen installer, in a terminal
#   ./install.sh --plain    plain text, questions asked inline (`update` uses this)
#   ./install.sh --dry-run  list what would be installed, change nothing
set -Eeuo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/common.sh"
for lib in "$REPO_DIR"/lib/*.sh; do
  [[ "$lib" == */common.sh ]] && continue
  # shellcheck source=/dev/null
  source "$lib"
done

# The install steps in order, "Title|function". The TUI shows them as its progress list.
STEPS=("Language, keyboard|setup_locale" "Repositories|setup_repos" "Packages|install_packages"
  "Flatpak apps|install_flatpaks" "Other apps|install_apps" "Your configuration|setup_user" "System|setup_system"
  "NVIDIA|setup_nvidia" "Optional steps|optional_steps")

preflight_checks() {
  [[ $EUID -ne 0 ]] || die "Run this as your normal user, not with sudo. It asks for your password when it needs it."
  fedora_version_ok /etc/os-release || die "This installer needs Fedora 44 or newer."
  curl -fsI --max-time 15 https://fedoraproject.org >/dev/null || die "No internet connection. Connect with nmtui, then run it again."
}

# sudo_session: asks for the password once and keeps sudo's timestamp fresh for the whole run.
sudo_session() {
  sudo -v
  # Keep sudo's timestamp fresh for the whole run.
  while sleep 50; do sudo -n true; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

# Questions asked at the end; a "no" is remembered so later runs (and `update`) don't ask again.
optional_steps() {
  # The TUI enrolls the fingerprint after it closes: enrolling needs the terminal.
  if [[ -z "${DEFER_FINGERPRINT:-}" ]]; then enroll_fingerprint; fi
  if home_snapshots_possible; then
    if home_snapshots_enabled; then
      setup_home_snapshots
    elif ask_once home-snapshots "Take hourly snapshots of /home, so deleted files can be restored (kept 7 days)?" y; then
      setup_home_snapshots
    fi
  fi
  # Once installed, every run keeps grub-btrfs current; the question only comes the first time.
  if sudo snapper -c root get-config >/dev/null 2>&1 && { [[ -f "$STATE_DIR/grub-btrfs-version" ]] ||
    ask_once grub-btrfs "Add system snapshots to the boot menu, to start the system as it was before an update?" y; }; then
    setup_grub_btrfs
  fi
  if [[ ! -f "$ARTCRAFT_APPIMAGE" ]] && ask_once artcraft "Install the ArtCraft Launcher (alpha creative apps)?" n; then
    install_artcraft
  fi
}

# enroll_fingerprint: offers enrollment when a reader is there and nothing is enrolled yet.
enroll_fingerprint() {
  local fp
  fp=$(fprintd-list "$USER" 2>&1 || true)
  if grep -q 'no fingers enrolled' <<<"$fp" && ask_once fingerprint "Enroll a fingerprint now (sudo, login, lock screen)?" y; then
    # As root: enrolling needs a polkit agent for the user, and a text console (first install) has none.
    sudo fprintd-enroll "$USER" || warn "Fingerprint enrollment didn't finish. Run fprintd-enroll later."
  fi
}

plain_install() {
  local step
  mkdir -p "$(dirname "$LOG_FILE")"
  exec > >(tee -a "$LOG_FILE") 2>&1
  trap 'warn "Stopped at line $LINENO. Full log: $LOG_FILE. Fix the problem and run ./install.sh again; finished steps are skipped."' ERR
  preflight_checks
  sudo_session
  for step in "${STEPS[@]}"; do
    log "${step%%|*}"
    "${step#*|}"
  done
  log "Done. Reboot to start Umbriel (Plasma is on the login screen as a fallback): systemctl reboot"
}

dry_run() {
  local group
  echo "Software groups: ${SOFTWARE_GROUPS-$ALL_GROUPS}"
  echo
  echo "dnf packages:"
  main_dnf_packages | sort | column -c "${COLUMNS:-100}"
  echo
  echo "KDE Plasma fallback: ${DNF_PLASMA[*]}"
  if group_on flatpak; then echo "Flatpak apps: ${FLATPAKS[*]}"; fi
  echo
  echo "Steps: $(printf '%s, ' "${STEPS[@]%%|*}" | sed 's/, $//')"
  echo "Nothing was changed."
}

usage() { sed -n '/^# Usage/,/--dry-run/s/^# \?//p' "$0"; }

main() {
  # A dry run changes nothing, not even the state folder.
  case "${1:-}" in --dry-run | -h | --help) ;; *) migrate_state ;; esac
  load_choices
  case "${1:-}" in
    --plain) plain_install ;;
    --dry-run) dry_run ;;
    -h | --help) usage ;;
    "")
      # The TUI needs a terminal; ASSUME=yes|no (unattended runs) and pipes get the plain installer.
      if [[ -t 0 && -t 1 && -z "${ASSUME:-}" ]]; then tui_main; else plain_install; fi
      ;;
    *) die "Unknown option $1. See ./install.sh --help." ;;
  esac
}

main "$@"
