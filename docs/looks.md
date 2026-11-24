# Looks

A look switches the wallpaper, and Noctalia takes the colors of the bar, panels, terminals, GTK and KDE apps, Luciole,
Firefox and the compositor's borders from it. Each look also sets the bar's style and the desktop widgets.

```bash
noctalia-preset            # list the looks; * marks the active one
noctalia-preset sakura     # use one (its wallpaper is downloaded the first time)
noctalia-preset off        # back to plain Ayu and the wallpaper you had before
```

| Look | Kind | Wallpaper | Style |
|---|---|---|---|
| `waterfall` | anime | forest gorge with waterfalls and a turquoise lake | faithful colors, glass capsule bar; time at the top, calendar and music on the right |
| `sakura` | anime | cherry-blossom street mirrored in rain water | like waterfall |
| `meadow` | anime | hilltop meadow under towering summer clouds | like waterfall, vibrant colors |
| `neon` | anime | neon city at night with glowing sakura | vibrant, floating capsules, glass panels |
| `fuji` | photo | Mount Fuji at sunrise, cherry blossoms, mirror lake | like waterfall |
| `alpine` | photo | green alpine lake with a chalet below snowy peaks | like waterfall |
| `twilight` | photo | Swiss lake at dusk with a lit castle | floating rounded bar, soft panels |
| `aurora` | photo | northern lights over a snowy fjord | floating capsules, glass panels |
| `dunes` | photo | desert dunes under a glowing evening sky | vibrant, floating rounded bar |
| `pixel` | pixel art | meadow under a wide summer sky | vibrant, glass capsule bar |
| `ridge` | flat art | mountain ridges and a watch tower at sunset | floating rounded bar, soft panels |
| `spirit` | illustration | night forest with a glowing spirit stag | floating capsules, glass panels |
| `synthwave` | illustration | neon mountains and a glowing waterfall under the stars | vibrant, floating capsules |

The wallpapers are picked from wallhaven.cc's most-favorited scenery in the styles r/unixporn rices use, at 2560x1440
or more (most 4K). They belong to their artists and photographers. Only waterfall's is downloaded during the install;
every other look fetches its wallpaper into `~/Pictures/Wallpapers` the first time you pick it.

The widget positions are made for a 1920x1080 screen; move them with Noctalia's Settings → Desktop → Toggle Editor.

## How a look is made

A look is a Noctalia config file in `config/noctalia/presets/NAME.toml` with two header lines:

```toml
# Preset "sakura": anime cherry-blossom street mirrored in rain water. ...
# wallpaper = ~/Pictures/Wallpapers/wallhaven-gwdvxq.jpg
# source = https://w.wallhaven.cc/full/gw/wallhaven-gwdvxq.jpg
[theme]
source           = "wallpaper"
wallpaper_scheme = "faithful"      # faithful, vibrant or m3-tonal-spot
...
```

The active look is linked as `~/.config/noctalia/30-preset.toml`, so it updates with `update`. Your own looks go in
`~/.config/noctalia-presets/NAME.toml` and win over a repo look of the same name. `# source = fedora-night` (or
`fedora-day`) makes the wallpaper from the installed Fedora release's own one (needs the `fNN-backgrounds-base`
package).
