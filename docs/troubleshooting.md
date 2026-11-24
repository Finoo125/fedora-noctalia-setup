# If something breaks

| Problem | What to do |
|---|---|
| A step of the installer failed | The installer shows where it stopped and the last log lines; the full log is `~/.cache/fedora-noctalia-setup/install.log`. Fix the cause and run `install.sh` again: finished steps are skipped. |
| Bad update | Open Btrfs Assistant → Snapper and restore the snapshot taken before the update. |
| Bad update and it won't boot | In GRUB, open **Fedora snapshots** and pick the snapshot from before the update. `/boot` isn't part of the snapshots, so choose a kernel that was already installed back then. The snapshot starts read-only and some services may complain; that's expected. Restore it in Btrfs Assistant and reboot. **Untested on real hardware so far.** |
| The compositor is broken | Pick another compositor or the fallback desktop (Plasma or GNOME) on the login screen, run `update` there, or restore a snapshot. |
| No desktop after login | Ctrl+Alt+F3 for a text console, log in, read the log above or `journalctl --user -b`. Pick the previous kernel in GRUB if a new one is the cause. |
| A keybinding does nothing | `keybinds` shows what is bound. niri has no scratchpad and Hyprland no overview. Check the compositor accepts its config (below). |
| A look shows no wallpaper | Its wallpaper is downloaded the first time; offline that fails. Run `noctalia-preset NAME` again when you're online. |
| Qt or KDE apps in the wrong colors | `QT_QPA_PLATFORMTHEME` must be `kde` (it is set in each compositor's defaults) and `plasma-integration` installed. Don't change Plasma's Appearance settings in the fallback. |
| A driver is missing | `./install.sh --scan` shows what the scan finds; tick it on the Drivers page or run `install.sh` again. |

## Check a compositor's config

```bash
umbriel config validate
niri validate
mango -c ~/.config/mango/config.conf -p
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

## Start over with a file

Every config file the installer created once is yours; delete it and run `install.sh` to get the current default.
To forget an answer you gave (a "no" to a question, your app choices), delete the matching file in
`~/.local/state/fedora-noctalia-setup/`.
