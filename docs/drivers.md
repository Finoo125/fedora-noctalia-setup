# Drivers

The installer scans the hardware and offers what the machine needs on the **Drivers** page. It reads PCI and USB
devices straight from `/sys`, so it works on a fresh Minimal Install where `lspci` and `lsusb` aren't installed yet.
Recommended drivers are ticked; optional ones are listed unticked.

```bash
./install.sh --scan    # the same list, in a terminal
```

| Hardware | Offered | Source |
|---|---|---|
| NVIDIA RTX 20 and newer, GTX 16 | RPM Fusion's driver: open kernel modules, CUDA, NVENC, suspend fixes; hybrid laptops run the desktop on the integrated GPU | RPM Fusion |
| AMD GPU | Vulkan and H.264/HEVC decoding (RPM Fusion's Mesa replaces Fedora's, which leaves the codecs out) | RPM Fusion |
| AMD GPU, optional | LACT (fans, clocks, power limits); ROCm (OpenCL and HIP for Blender, Resolve, local AI) | Terra, Fedora |
| Intel GPU | Hardware video decoding for new and older GPUs, Vulkan, a GPU monitor | RPM Fusion |
| Intel GPU, optional | oneAPI compute (OpenCL, Level Zero) | Fedora |
| Intel NPU (Core Ultra) | NPU driver (OpenVINO) | Fedora |
| Broadcom Wi-Fi the kernel doesn't drive | `wl` | RPM Fusion |
| Intel IPU6 webcam | libcamera and its PipeWire plugin | Fedora |
| Logitech Unifying/Bolt receiver | Solaar | Fedora |
| Logitech G, SteelSeries, Roccat mouse | Piper | Fedora |
| Razer device | OpenRazer (you're added to the `plugdev` group) | Terra |
| Corsair device | ckb-next | Fedora |
| Xbox Wireless Adapter | xone | Terra |
| Game controller (PlayStation, Xbox, Nintendo, 8BitDo, Steam) | device rules | Fedora |
| Smart card reader | PC/SC, CCID, OpenSC | Fedora |
| Accelerometer (2-in-1) | rotation and light sensors | Fedora |
| ASUS laptop | asusctl (fans, keyboard light, charge limit) | Terra |
| Fingerprint reader | turns on fingerprint login in Extras | Fedora |

An NVIDIA card older than RTX 20 is reported but not set up: it needs RPM Fusion's legacy driver
([rpmfusion.org/Howto/NVIDIA](https://rpmfusion.org/Howto/NVIDIA)).

Without the full-screen installer (`--plain`, `update`) the recommended drivers for the hardware found are installed,
or the ones you chose in the installer if you used it.

## NVIDIA

**Untested on real hardware so far.**

- **Secure Boot:** you set a one-time password. After the reboot a blue **MOK management** screen appears:
  Enroll MOK → Continue → Yes → password → Reboot. That screen uses a **US keyboard layout**, so use only letters a–x
  and digits in the password.
- **Hybrid laptops:** start a game on the NVIDIA GPU with `nvidia-run <app>`, or the Steam launch option
  `nvidia-run %command%`.
- `update` rebuilds the module for a new kernel.

## Adding a driver

A row in `DRIVERS` in `lib/drivers.sh` (`id|label|default|source|packages|what it does`) and a match in `hw_scan` on
the PCI or USB ids. `tests/test_drivers.sh` runs the scanner on made-up hardware.
