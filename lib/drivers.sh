# shellcheck shell=bash
# The driver scanner: reads the hardware from /sys (no lspci or lsusb needed, so it works on a fresh Minimal Install)
# and recommends what this machine needs: GPU drivers for NVIDIA, AMD and Intel, Wi-Fi, cameras, input devices.
#   ./install.sh --scan   prints what it found

# "id|label|default 1/0|source|packages|what it does". Only rows whose hardware is found are offered.
# Source as in lib/catalog.sh; "nvidia" is installed by setup_nvidia (Secure Boot, akmods, hybrid laptops).
DRIVERS=(
  "nvidia|NVIDIA driver|1|nvidia|akmod-nvidia xorg-x11-drv-nvidia-cuda|RPM Fusion's driver for RTX 20 to RTX 50 and GTX 16: open kernel modules, CUDA, NVENC, suspend fixes. With Secure Boot you set a one-time password."
  "amd-graphics|AMD graphics|1|rpmfusion|mesa-vulkan-drivers radeontop|Vulkan for games, and H.264/HEVC video decoding: RPM Fusion's Mesa (mesa-va-drivers-freeworld) replaces Fedora's, which leaves the codecs out."
  "amd-lact|AMD GPU control (LACT)|0|terra|lact|Fan curves, clocks, voltage and power limits for AMD cards."
  "amd-rocm|AMD GPU compute (ROCm)|0|dnf|rocm-opencl rocm-hip rocminfo rocm-smi|OpenCL and HIP for Blender, DaVinci Resolve and local AI."
  "intel-graphics|Intel graphics|1|rpmfusion|intel-media-driver libva-intel-driver mesa-vulkan-drivers nvtop|Hardware video decoding (new and older Intel GPUs), Vulkan, and a GPU monitor."
  "intel-compute|Intel GPU compute (oneAPI)|0|dnf|intel-compute-runtime intel-level-zero oneapi-level-zero|OpenCL and Level Zero for Blender, DaVinci Resolve and local AI."
  "intel-npu|Intel NPU|1|dnf|intel-npu-driver|The AI accelerator of Core Ultra CPUs (OpenVINO)."
  "broadcom-wifi|Broadcom Wi-Fi (wl)|1|rpmfusion|akmod-wl broadcom-wl|Broadcom's driver for Wi-Fi chips the kernel's own driver doesn't cover."
  "ipu6-camera|Intel IPU6 webcam|1|dnf|libcamera pipewire-plugin-libcamera|The webcam of many 2021+ Intel laptops, through libcamera and PipeWire."
  "logitech|Logitech devices (Solaar)|1|dnf|solaar|Pairing, battery and settings for Logitech Unifying and Bolt receivers."
  "gaming-mouse|Gaming mouse settings (Piper)|1|dnf|piper libratbag-ratbagd|Buttons, DPI and lights of Logitech G, SteelSeries and Roccat mice."
  "razer|Razer devices (OpenRazer)|1|terra|openrazer-meta|Lights and settings of Razer keyboards and mice."
  "corsair|Corsair devices (ckb-next)|1|dnf|ckb-next|Lights and macros of Corsair keyboards and mice."
  "xbox-adapter|Xbox Wireless Adapter (xone)|1|terra|xone|Xbox controllers through Microsoft's USB wireless adapter."
  "controllers|Game controllers|1|dnf|steam-devices|Device rules for PlayStation, Xbox, Nintendo, 8BitDo and Steam controllers."
  "smartcard|Smart card reader|1|dnf|pcsc-lite pcsc-lite-ccid opensc|ID cards, signature cards and security tokens."
  "sensors|Rotation and light sensors|1|dnf|iio-sensor-proxy|Screen rotation and auto-brightness on 2-in-1s and tablets."
  "asus|ASUS laptop controls (asusctl)|1|terra|asusctl|Fan profiles, keyboard lights and charge limit on ASUS laptops."
)

declare -gA DRV_LABEL DRV_DEFAULT DRV_SOURCE DRV_PACKAGES DRV_ABOUT HW_FOUND
DRV_IDS=()
drivers_index() {
  local entry id label def source pkgs about
  for entry in "${DRIVERS[@]}"; do
    IFS='|' read -r id label def source pkgs about <<<"$entry"
    DRV_IDS+=("$id")
    DRV_LABEL[$id]=$label DRV_DEFAULT[$id]=$def DRV_SOURCE[$id]=$source DRV_PACKAGES[$id]=$pkgs DRV_ABOUT[$id]=$about
  done
}
drivers_index

# Broadcom Wi-Fi chips that need wl (the kernel's brcmfmac/b43 don't drive them well).
WL_DEVICES=" 4311 4312 4313 4315 4328 4329 432a 432b 432c 432d 4331 4353 4357 4358 4359 4365 43a0 43b1 "
# Intel IPU6 camera controllers (Tiger Lake to Meteor Lake).
IPU6_DEVICES=" 9a19 9a39 4e19 465d 462e a75d 7d19 "

# hw_pci [SYSFS] -> "vendor device class" per PCI device, hex without 0x (class = base+subclass, e.g. 0300).
hw_pci() {
  local d
  for d in "${1:-/sys/bus/pci/devices}"/*; do
    [[ -r "$d/vendor" ]] || continue
    printf '%s %s %s\n' "$(sed 's/^0x//' "$d/vendor")" "$(sed 's/^0x//' "$d/device")" "$(sed 's/^0x//; s/..$//' "$d/class")"
  done
}

# hw_usb [SYSFS] -> "vendor product interface-classes" per USB device (classes comma-separated, e.g. 0b,).
hw_usb() {
  local d i classes
  for d in "${1:-/sys/bus/usb/devices}"/*; do
    [[ -r "$d/idVendor" ]] || continue
    classes=""
    for i in "$d"/*:*/bInterfaceClass; do [[ -r "$i" ]] && classes+="$(<"$i"),"; done
    printf '%s %s %s\n' "$(<"$d/idVendor")" "$(<"$d/idProduct")" "${classes:-,}"
  done
}

# nvidia_generation DEVICE -> modern (RTX 20 / GTX 16 and newer: device ids from 1e00) or legacy.
nvidia_generation() { if ((16#$1 >= 16#1e00)); then echo modern; else echo legacy; fi; }

# hw_scan [PCI_LINES USB_LINES VENDOR IIO]: fills HW_FOUND[id] with what was found, for every driver row this
# machine needs, plus HW_FOUND[fingerprint-reader]. Without arguments it reads /sys.
hw_scan() {
  local pci=${1-$(hw_pci)} usb=${2-$(hw_usb)} vendor=${3-$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)} iio=${4-}
  local v d c gpus=0
  if [[ -z "${4+set}" ]] && compgen -G '/sys/bus/iio/devices/iio:device*/in_accel*' >/dev/null; then iio=1; fi
  HW_FOUND=()
  while read -r v d c; do
    [[ -n "$v" ]] || continue
    case "$v:${c:0:2}" in 10de:03 | 1002:03 | 8086:03) gpus=$((gpus + 1)) ;; esac
    case "$v:$c" in
      10de:03*)
        if [[ "$(nvidia_generation "$d")" == modern ]]; then HW_FOUND[nvidia]="NVIDIA GPU ($v:$d)"
        else HW_FOUND[nvidia-legacy]="NVIDIA GPU older than RTX 20 ($v:$d)"; fi
        ;;
      1002:03*)
        HW_FOUND[amd-graphics]="AMD GPU ($v:$d)" HW_FOUND[amd-lact]=${HW_FOUND[amd-graphics]}
        HW_FOUND[amd-rocm]=${HW_FOUND[amd-graphics]}
        ;;
      8086:03*) HW_FOUND[intel-graphics]="Intel GPU ($v:$d)" HW_FOUND[intel-compute]=${HW_FOUND[intel-graphics]} ;;
      8086:1200) HW_FOUND[intel-npu]="Intel NPU ($v:$d)" ;;
      14e4:0280) if [[ "$WL_DEVICES" == *" $d "* ]]; then HW_FOUND[broadcom-wifi]="Broadcom Wi-Fi ($v:$d)"; fi ;;
      8086:0480) if [[ "$IPU6_DEVICES" == *" $d "* ]]; then HW_FOUND[ipu6-camera]="Intel IPU6 camera ($v:$d)"; fi ;;
    esac
  done <<<"$pci"
  if [[ -n "${HW_FOUND[nvidia]:-}" ]] && ((gpus > 1)); then HW_FOUND[nvidia]+=", hybrid laptop"; fi
  while read -r v d c; do
    [[ -n "$v" ]] || continue
    case "$v:$d" in
      046d:c52b | 046d:c534 | 046d:c539 | 046d:c53a | 046d:c53f | 046d:c545 | 046d:c547 | 046d:c548)
        HW_FOUND[logitech]="Logitech receiver ($v:$d)" ;;
      046d:c08? | 046d:c09? | 1038:* | 1e7d:*) HW_FOUND[gaming-mouse]="gaming mouse ($v:$d)" ;;
      1532:*) HW_FOUND[razer]="Razer device ($v:$d)" ;;
      1b1c:*) HW_FOUND[corsair]="Corsair device ($v:$d)" ;;
      045e:02e6 | 045e:02fe | 045e:02f9 | 045e:091e) HW_FOUND[xbox-adapter]="Xbox Wireless Adapter ($v:$d)" ;;
      054c:* | 057e:* | 2dc8:* | 28de:* | 045e:02??) HW_FOUND[controllers]="game controller ($v:$d)" ;;
      06cb:* | 27c6:* | 138a:* | 10a5:* | 2808:* | 1c7a:* | 04f3:0c??) HW_FOUND[fingerprint-reader]="fingerprint reader ($v:$d)" ;;
    esac
    if [[ ",$c" == *",0b,"* ]]; then HW_FOUND[smartcard]="smart card reader ($v:$d)"; fi
  done <<<"$usb"
  if [[ -n "$iio" ]]; then HW_FOUND[sensors]="accelerometer"; fi
  if [[ "$vendor" == ASUS* ]]; then HW_FOUND[asus]="ASUS laptop"; fi
  HW_SCANNED=1
}

# found_drivers -> the driver rows this machine needs, in table order.
found_drivers() {
  local id
  [[ -n "${HW_SCANNED:-}" ]] || hw_scan
  for id in "${DRV_IDS[@]}"; do if [[ -n "${HW_FOUND[$id]:-}" ]]; then echo "$id"; fi; done
}

# driver_on ID -> 0 when driver row ID is chosen: DRIVER_ITEMS, else found on this machine and on by default.
driver_on() {
  if [[ -n "${DRIVER_ITEMS+set}" ]]; then [[ " $DRIVER_ITEMS " == *" $1 "* ]]; return; fi
  [[ -n "${HW_SCANNED:-}" ]] || hw_scan
  [[ -n "${HW_FOUND[$1]:-}" && "${DRV_DEFAULT[$1]}" == 1 ]]
}

# chosen_driver_packages KIND -> packages of chosen driver rows: rpm (dnf, rpmfusion, terra) or terra.
# NVIDIA's packages are installed by setup_nvidia, not here.
chosen_driver_packages() {
  local id
  for id in "${DRV_IDS[@]}"; do
    driver_on "$id" || continue
    case "$1:${DRV_SOURCE[$id]}" in
      rpm:dnf | rpm:rpmfusion | rpm:terra | terra:terra) tr ' ' '\n' <<<"${DRV_PACKAGES[$id]}" ;;
    esac
  done | awk '!seen[$0]++'
}

# all_driver_packages KIND -> like chosen_driver_packages for every row (CI checks they exist; Terra's allowlist).
all_driver_packages() { DRIVER_ITEMS="${DRV_IDS[*]}" chosen_driver_packages "$1"; }

# scan_report: what --scan prints.
scan_report() {
  local id mark
  hw_scan
  echo "Hardware that needs or benefits from extra drivers:"
  if ! found_drivers | grep -q .; then echo "  nothing: the standard Fedora drivers cover this machine."; fi
  for id in $(found_drivers); do
    if [[ "${DRV_DEFAULT[$id]}" == 1 ]]; then mark="recommended"; else mark="optional"; fi
    printf '  %-32s %-12s %s\n' "${DRV_LABEL[$id]}" "$mark" "${HW_FOUND[$id]}"
    printf '  %-32s %-12s %s\n' "" "" "${DRV_PACKAGES[$id]}"
  done
  if [[ -n "${HW_FOUND[nvidia-legacy]:-}" ]]; then
    echo "  ${HW_FOUND[nvidia-legacy]}: not supported here, see https://rpmfusion.org/Howto/NVIDIA (legacy driver)."
  fi
  if [[ -n "${HW_FOUND[fingerprint-reader]:-}" ]]; then
    echo "  ${HW_FOUND[fingerprint-reader]}: fingerprint login can be set up (Extras)."
  fi
}
