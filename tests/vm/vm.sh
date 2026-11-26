#!/usr/bin/env bash
# A Fedora 45 Minimal Install VM for testing the installer for real (QEMU/KVM, libvirt user session).
#
#   vm.sh deps      the packages to install on the host (prints the dnf command)
#   vm.sh create    unattended Minimal Install from the netinstall tree, then keeps a clean base
#   vm.sh start     boot the VM            vm.sh view     open its screen (virt-viewer, 3D on)
#   vm.sh ssh [CMD] log in as tester       vm.sh stop     shut it down
#   vm.sh reset     back to the fresh install (drops everything since `create`)
#   vm.sh status    state and disk use     vm.sh destroy  delete the VM and its files
#
# User tester, password tester (sudo with password, like a real install). SSH on 127.0.0.1:2222.
set -euo pipefail

NAME=noctalia-test
CONN=qemu:///session
DIR=${XDG_DATA_HOME:-$HOME/.local/share}/noctalia-vm
DISK=$DIR/disk.qcow2
BASE=$DIR/base.qcow2
KEY=$DIR/id_ed25519
SSH_PORT=2222
LOCATION=https://download.fedoraproject.org/pub/fedora/linux/releases/45/Everything/x86_64/os/
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

virsh() { LC_ALL=C command virsh --connect "$CONN" "$@"; }
die() { echo "vm.sh: $*" >&2; exit 1; }
exists() { virsh dominfo "$NAME" &>/dev/null; }
running() { [[ $(virsh domstate "$NAME" 2>/dev/null) == running ]]; }
nvram() { virsh dumpxml "$NAME" | sed -n 's|.*<nvram[^>]*>\(.*\)</nvram>.*|\1|p'; }

need_tools() {
  local t missing=()
  for t in virsh virt-install virt-viewer qemu-img passt; do command -v "$t" &>/dev/null || missing+=("$t"); done
  ((${#missing[@]} == 0)) || die "missing ${missing[*]}; run: $0 deps"
}

ssh_vm() {
  ssh -i "$KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR tester@127.0.0.1 "$@"
}

keep_base() {  # the fresh install becomes a read-only base; the VM runs on an overlay
  mv "$DISK" "$BASE"
  chmod a-w "$BASE"
  cp "$(nvram)" "$DIR/base_VARS.fd"
  qemu-img create -q -f qcow2 -b "$BASE" -F qcow2 "$DISK"
}

case ${1:-} in
  deps)
    echo "sudo dnf install -y @virtualization passt"
    ;;
  create)
    need_tools
    exists && die "$NAME exists already (reset or destroy it)"
    mkdir -p "$DIR"
    [[ -f $KEY ]] || ssh-keygen -q -t ed25519 -N '' -C "$NAME" -f "$KEY"
    sed "s|@SSHKEY@|$(cat "$KEY.pub")|" "$HERE/minimal.ks" >"$DIR/minimal.ks"
    rm -f "$DIR/serial.log"
    echo "Installing Fedora 45 Minimal (unattended, ~10-20 min); progress: tail -f $DIR/serial.log"
    virt-install --connect "$CONN" --name "$NAME" \
      --memory 8192 --vcpus 4 --cpu host-passthrough \
      --osinfo detect=on,require=off \
      --boot uefi \
      --disk "path=$DISK,size=40,format=qcow2,bus=virtio" \
      --network "passt,portForward0.proto=tcp,portForward0.address=127.0.0.1,portForward0.range0.start=$SSH_PORT,portForward0.range0.to=22" \
      --video virtio,accel3d=yes --graphics spice,gl.enable=yes,listen=none \
      --serial "file,path=$DIR/serial.log" \
      --location "$LOCATION" \
      --initrd-inject "$DIR/minimal.ks" \
      --extra-args "inst.ks=file:/minimal.ks console=ttyS0,115200" \
      --noautoconsole --noreboot --wait -1
    grep -aq 'reboot: Power down' "$DIR/serial.log" || die "install did not finish; see $DIR/serial.log"
    keep_base
    echo "Done. Fresh Minimal Install kept as base. Next: $0 start && $0 view"
    ;;
  start)
    running || virsh start "$NAME"
    echo "Waiting for SSH..."
    for _ in {1..60}; do ssh_vm -o ConnectTimeout=2 true 2>/dev/null && { echo "Up: $0 ssh"; exit 0; }; sleep 2; done
    die "no SSH after 2 min (look with: $0 view)"
    ;;
  view) virt-viewer --connect "$CONN" --attach "$NAME" & disown ;;
  ssh) shift; ssh_vm -t "$@" ;;
  stop) running && { virsh shutdown "$NAME"; for _ in {1..30}; do running || break; sleep 2; done; } || true ;;
  reset)
    [[ -f $BASE ]] || die "no base yet (run create)"
    running && virsh destroy "$NAME" >/dev/null
    rm -f "$DISK"
    qemu-img create -q -f qcow2 -b "$BASE" -F qcow2 "$DISK"
    cp "$DIR/base_VARS.fd" "$(nvram)"
    echo "Back to the fresh Minimal Install."
    ;;
  status)
    virsh domstate "$NAME" 2>/dev/null || echo "not created"
    du -sh "$DIR"/*.qcow2 2>/dev/null || true
    ;;
  destroy)
    if exists; then
      running && virsh destroy "$NAME" >/dev/null
      virsh undefine "$NAME" --nvram >/dev/null
    fi
    rm -rf "$DIR"
    echo "Deleted."
    ;;
  *) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
