#!/usr/bin/env bash
# The driver scanner, on made-up hardware (PCI: "vendor device class", USB: "vendor product interface-classes").
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh
source lib/common.sh
source lib/drivers.sh

found() { found_drivers | tr '\n' ' ' | sed 's/ $//'; }

hw_scan "8086 46a8 0300
8086 51f0 0280" "04f3 0c7e ff,
058f 9540 0b," "HP" ""
assert_eq "intel-graphics intel-compute smartcard" "$(found)" "an Intel laptop with a smart card reader"
assert_true  "its fingerprint reader is noticed"   test -n "${HW_FOUND[fingerprint-reader]:-}"
assert_true  "Intel graphics is recommended"       driver_on intel-graphics
assert_false "Intel compute is only offered"       driver_on intel-compute

hw_scan "8086 9a49 0300
10de 2860 0302" "" "LENOVO" ""
assert_eq "nvidia intel-graphics intel-compute" "$(found)" "a hybrid laptop with an RTX 40"
assert_true "it is called hybrid"                  grep -q hybrid <<<"${HW_FOUND[nvidia]}"

hw_scan "10de 1c03 0300" "" "" ""
assert_eq "" "$(found)" "a GTX 1060 gets no driver row"
assert_true "but is reported as too old"           test -n "${HW_FOUND[nvidia-legacy]:-}"

hw_scan "1002 73df 0300
1002 15bf 0300" "" "ASUSTeK COMPUTER INC." 1
assert_eq "amd-graphics amd-lact amd-rocm sensors asus" "$(found)" "an ASUS 2-in-1 with AMD graphics"
assert_false "LACT is optional"                    driver_on amd-lact

hw_scan "14e4 4365 0280
14e4 43ba 0280" "" "" ""
assert_eq "broadcom-wifi" "$(found)" "a Broadcom chip that needs wl"
hw_scan "14e4 43ba 0280" "" "" ""
assert_eq "" "$(found)" "a Broadcom chip the kernel drives gets nothing"

hw_scan "8086 a75d 0480" "046d c548 03,
1532 0084 03,
045e 02fe ff,
054c 0ce6 03,
1b1c 1b2d 03,
1038 1836 03," "" ""
assert_eq "ipu6-camera logitech gaming-mouse razer corsair xbox-adapter controllers" "$(found)" "camera and USB devices"

DRIVER_ITEMS="razer"
assert_true  "a saved choice wins"                 driver_on razer
assert_false "over what the scan recommends"       driver_on logitech
unset DRIVER_ITEMS

# The sysfs readers, on a fake /sys.
sys=$(mktemp -d); trap 'rm -rf "$sys"' EXIT
mkdir -p "$sys/pci/0000:00:02.0" "$sys/usb/3-1/3-1:1.0"
printf '0x8086\n' >"$sys/pci/0000:00:02.0/vendor"; printf '0x46a8\n' >"$sys/pci/0000:00:02.0/device"
printf '0x030000\n' >"$sys/pci/0000:00:02.0/class"
printf '058f\n' >"$sys/usb/3-1/idVendor"; printf '9540\n' >"$sys/usb/3-1/idProduct"
printf '0b\n' >"$sys/usb/3-1/3-1:1.0/bInterfaceClass"
assert_eq "8086 46a8 0300" "$(hw_pci "$sys/pci")" "PCI devices are read from sysfs"
assert_eq "058f 9540 0b," "$(hw_usb "$sys/usb")" "USB devices and their interface classes are read from sysfs"
finish
