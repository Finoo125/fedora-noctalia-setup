# shellcheck shell=bash
# Monitors: detected from /sys/class/drm and their EDID (so it works on a text console, before any compositor runs),
# arranged in the installer's Monitors page or with `monitors`, and written into each compositor's own syntax:
#   ~/.config/umbriel/monitors.toml  ~/.config/niri/monitors.kdl  ~/.config/mango/monitors.conf  ~/.config/hypr/monitors.lua
# External monitors are matched by make, model and serial (USB-C docks rename ports), the laptop panel by its connector.
# A rule only applies while its monitor is connected, so docked and undocked both work; dock-watch turns the laptop
# panel off while docked when you chose that.

MONITORS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fedora-noctalia-setup/monitors.conf"
MON_SCALES=(1 1.25 1.5 1.75 2)
MON_ROTATIONS=(0 90 180 270)

declare -gA MON_NAME MON_MAKE MON_MODEL MON_SERIAL MON_W MON_H MON_INTERNAL MON_MM MON_ROT MON_SCALE MON_ON MON_BELOW
declare -gA MON_X MON_Y
MON_IDS=() MON_ORDER=()
MON_ALIGN=top MON_LAPTOP_DOCKED=on

# pnp_name CODE [PNP_IDS] -> the manufacturer's name for a three-letter PNP id, the id itself when unknown.
pnp_name() {
  local name
  name=$(awk -F'\t' -v c="$1" '$1 == c { print $2; exit }' "${2:-/usr/share/hwdata/pnp.ids}" 2>/dev/null)
  echo "${name:-$1}"
}

# edid_info FILE -> "make|model|serial|width_mm" the way wlroots and niri name a monitor (libdisplay-info): the model is
# the EDID's name or else the product code (0x1506), the serial its serial string, else the number (0x0000ABCD), else
# "Unknown".
edid_info() {
  local -a b
  local i t code make model="" serial="" num j c
  mapfile -t b < <(od -An -tx1 -v "$1" | tr -s ' ' '\n' | grep .)
  ((${#b[@]} >= 128)) || return 1
  code=$((16#${b[8]}${b[9]}))
  # shellcheck disable=SC2059 # octal escapes built on purpose: EDID letters are 5-bit codes
  make=$(printf "\\$(printf '%03o' $((((code >> 10) & 31) + 64)))\\$(printf '%03o' $((((code >> 5) & 31) + 64)))\\$(printf '%03o' $(((code & 31) + 64)))")
  for i in 54 72 90 108; do
    [[ "${b[i]}${b[i + 1]}${b[i + 2]}" == 000000 ]] || continue
    t=${b[i + 3]} c=""
    for ((j = i + 5; j < i + 18; j++)); do
      [[ "${b[j]}" == 0a ]] && break
      # shellcheck disable=SC2059 # one byte as a character
      c+=$(printf "\\$(printf '%03o' $((16#${b[j]})))")
    done
    c=${c%"${c##*[![:space:]]}"}
    case "$t" in fc) model=$c ;; ff) serial=$c ;; esac
  done
  [[ -n "$model" ]] || model=$(printf '0x%04X' $((16#${b[11]}${b[10]})))
  if [[ -z "$serial" ]]; then
    num=$((16#${b[15]}${b[14]}${b[13]}${b[12]}))
    if ((num)); then serial=$(printf '0x%08X' "$num"); else serial=Unknown; fi
  fi
  printf '%s|%s|%s|%s\n' "$make" "$model" "$serial" "$((16#${b[21]} * 10))"
}

# mon_scan [DRM_DIR PNP_IDS]: the connected monitors into MON_* (connector names in MON_IDS).
mon_scan() {
  local d c make model serial mm mode
  MON_IDS=()
  for d in "${1:-/sys/class/drm}"/card*-*; do
    [[ -r "$d/status" && "$(<"$d/status")" == connected ]] || continue
    c=${d##*/}
    c=${c#card*-}
    [[ "$c" == Writeback* ]] && continue
    mode=$(head -1 "$d/modes" 2>/dev/null)
    [[ "$mode" == *x* ]] || continue
    IFS='|' read -r make model serial mm < <(edid_info "$d/edid" 2>/dev/null || echo "Unknown|Unknown|Unknown|0")
    make=$(pnp_name "$make" "${2:-}")
    MON_IDS+=("$c")
    MON_MAKE[$c]=$make MON_MODEL[$c]=$model MON_SERIAL[$c]=$serial MON_MM[$c]=$mm
    MON_NAME[$c]="$make $model $serial"
    MON_W[$c]=${mode%x*} MON_H[$c]=${mode#*x}
    MON_H[$c]=${MON_H[$c]%%[!0-9]*}
    if [[ "$c" == eDP* || "$c" == LVDS* || "$c" == DSI* ]]; then MON_INTERNAL[$c]=1; else MON_INTERNAL[$c]=""; fi
  done
  return 0
}

# mon_auto_scale ID -> a starting scale from the pixel density: 1 up to ~160 PPI, 1.5 up to ~230, else 2.
mon_auto_scale() {
  local mm=${MON_MM[$1]:-0} ppi
  ((mm > 0)) || { echo 1; return; }
  ppi=$((MON_W[$1] * 254 / (mm * 10)))
  if ((ppi < 160)); then echo 1; elif ((ppi < 230)); then echo 1.5; else echo 2; fi
}

# mon_internal -> the laptop panel's connector, empty on a desktop.
mon_internal() {
  local c
  for c in "${MON_IDS[@]}"; do if [[ -n "${MON_INTERNAL[$c]}" ]]; then echo "$c"; return; fi; done
}

# mon_defaults: everything on, unrotated, scaled by density; externals in connector order, the laptop on the right.
mon_defaults() {
  local c
  MON_ORDER=() MON_ALIGN=top MON_LAPTOP_DOCKED=on
  for c in "${MON_IDS[@]}"; do
    MON_ROT[$c]=0 MON_SCALE[$c]=$(mon_auto_scale "$c") MON_ON[$c]=1 MON_BELOW[$c]=""
    [[ -n "${MON_INTERNAL[$c]}" ]] || MON_ORDER+=("$c")
  done
  for c in "${MON_IDS[@]}"; do [[ -z "${MON_INTERNAL[$c]}" ]] || MON_ORDER+=("$c"); done
}

# mon_load: the saved layout over the defaults, for the monitors connected now (matched by name).
mon_load() {
  local key value name rot scale on pos below c
  local -A at=()
  local o
  mon_defaults
  [[ -f "$MONITORS_FILE" ]] || return 0
  while IFS='=' read -r key value; do
    case "$key" in
      align) MON_ALIGN=$value ;;
      laptop-docked) MON_LAPTOP_DOCKED=$value ;;
      monitor)
        IFS='|' read -r name rot scale on pos below <<<"$value"
        for c in "${MON_IDS[@]}"; do
          [[ "${MON_NAME[$c]}" == "$name" ]] || continue
          MON_ROT[$c]=$rot MON_SCALE[$c]=$scale MON_ON[$c]=$on MON_BELOW[$c]=$below at[$c]=$pos
        done
        ;;
    esac
  done <"$MONITORS_FILE"
  # Saved positions first (in their order), monitors seen for the first time after them.
  local -a order=()
  for c in $(for o in "${!at[@]}"; do echo "${at[$o]} $o"; done | sort -n | cut -d' ' -f2); do order+=("$c"); done
  for c in "${MON_ORDER[@]}"; do [[ -n "${at[$c]+set}" ]] || order+=("$c"); done
  MON_ORDER=("${order[@]}")
}

# mon_save: the layout, by monitor name, so it is found again whatever port the dock uses.
mon_save() {
  local i c
  mkdir -p "$(dirname "$MONITORS_FILE")"
  {
    echo "# Your monitor layout, written by the installer's Monitors page or \`monitors\`."
    echo "align=$MON_ALIGN"
    echo "laptop-docked=$MON_LAPTOP_DOCKED"
    for i in "${!MON_ORDER[@]}"; do
      c=${MON_ORDER[i]}
      echo "monitor=${MON_NAME[$c]}|${MON_ROT[$c]}|${MON_SCALE[$c]}|${MON_ON[$c]}|$i|${MON_BELOW[$c]}"
    done
  } >"$MONITORS_FILE"
}

# mon_size ID -> "width height" in layout pixels: resolution / scale, swapped when turned 90 or 270 degrees.
mon_size() {
  local w h
  w=$(awk -v p="${MON_W[$1]}" -v s="${MON_SCALE[$1]}" 'BEGIN { printf "%d", p / s + 0.5 }')
  h=$(awk -v p="${MON_H[$1]}" -v s="${MON_SCALE[$1]}" 'BEGIN { printf "%d", p / s + 0.5 }')
  case "${MON_ROT[$1]}" in 90 | 270) echo "$h $w" ;; *) echo "$w $h" ;; esac
}

# mon_layout: MON_X/MON_Y for every monitor that is on. The row goes left to right, aligned at the top, middle or
# bottom; monitors marked "below" sit centered under the row (a laptop under its external screens).
mon_layout() {
  local c w h x=0 rowh=0 belw=0 bx
  for c in "${MON_ORDER[@]}"; do
    [[ -n "${MON_ON[$c]}" && -z "${MON_BELOW[$c]}" ]] || continue
    read -r w h < <(mon_size "$c")
    ((h > rowh)) && rowh=$h
  done
  for c in "${MON_ORDER[@]}"; do
    [[ -n "${MON_ON[$c]}" && -z "${MON_BELOW[$c]}" ]] || continue
    read -r w h < <(mon_size "$c")
    MON_X[$c]=$x
    case "$MON_ALIGN" in
      bottom) MON_Y[$c]=$((rowh - h)) ;;
      center) MON_Y[$c]=$(((rowh - h) / 2)) ;;
      *) MON_Y[$c]=0 ;;
    esac
    x=$((x + w))
  done
  for c in "${MON_ORDER[@]}"; do
    [[ -n "${MON_ON[$c]}" && -n "${MON_BELOW[$c]}" ]] || continue
    read -r w h < <(mon_size "$c")
    belw=$((belw + w))
  done
  bx=$(((x - belw) / 2))
  ((bx < 0)) && bx=0
  for c in "${MON_ORDER[@]}"; do
    [[ -n "${MON_ON[$c]}" && -n "${MON_BELOW[$c]}" ]] || continue
    read -r w h < <(mon_size "$c")
    MON_X[$c]=$bx MON_Y[$c]=$rowh
    bx=$((bx + w))
  done
}

# mon_key ID -> how a compositor's config names the monitor: the laptop panel by connector, the others by name.
mon_key() { if [[ -n "${MON_INTERNAL[$1]}" ]]; then echo "$1"; else echo "${MON_NAME[$1]}"; fi; }

# --- Umbriel (TOML)
mon_umbriel() {
  local c t
  echo "# Written by fedora-noctalia-setup from your monitor layout (monitors.conf). Change it with \`monitors\`."
  for c in "${MON_ORDER[@]}"; do
    printf '\n[output."%s"]\n' "$(mon_key "$c")"
    if [[ -z "${MON_ON[$c]}" ]]; then echo "enabled = false"; continue; fi
    t=${MON_ROT[$c]}
    [[ "$t" == 0 ]] && t=normal
    printf 'position = [%d, %d]\nscale = %s\ntransform = "%s"\nworkspaces = 5\nworkspace_axis = "horizontal"\n' \
      "${MON_X[$c]}" "${MON_Y[$c]}" "${MON_SCALE[$c]}" "$t"
  done
}

# --- niri (KDL)
mon_niri() {
  local c t
  echo "// Written by fedora-noctalia-setup from your monitor layout (monitors.conf). Change it with \`monitors\`."
  for c in "${MON_ORDER[@]}"; do
    if [[ -z "${MON_ON[$c]}" ]]; then printf 'output "%s" {\n    off\n}\n' "$(mon_key "$c")"; continue; fi
    t=${MON_ROT[$c]}
    [[ "$t" == 0 ]] && t=normal
    printf 'output "%s" {\n    scale %s\n    transform "%s"\n    position x=%d y=%d\n}\n' \
      "$(mon_key "$c")" "${MON_SCALE[$c]}" "$t" "${MON_X[$c]}" "${MON_Y[$c]}"
  done
}

# --- MangoWC: monitor_rule=name:...|make:..,model:..,x,y,scale,rr
# shellcheck disable=SC2001 # a character class, not one fixed string
mon_regex() { sed 's/[][\\.*^$+?(){}|]/\\&/g' <<<"$1"; }
mon_mango() {
  local c match rr
  echo "# Written by fedora-noctalia-setup from your monitor layout (monitors.conf). Change it with \`monitors\`."
  for c in "${MON_ORDER[@]}"; do
    if [[ -n "${MON_INTERNAL[$c]}" ]]; then
      match="name:^$c\$"
    else
      match="make:^$(mon_regex "${MON_MAKE[$c]}")\$,model:^$(mon_regex "${MON_MODEL[$c]}")\$"
      [[ "${MON_SERIAL[$c]}" == Unknown ]] || match+=",serial:^$(mon_regex "${MON_SERIAL[$c]}")\$"
    fi
    if [[ -z "${MON_ON[$c]}" ]]; then echo "monitor_rule=$match,disable:1"; continue; fi
    rr=$((MON_ROT[$c] / 90))
    # No width/height: MangoWC wants them only together with the refresh rate; it then takes the preferred mode.
    printf 'monitor_rule=%s,x:%d,y:%d,scale:%s,rr:%d\n' "$match" "${MON_X[$c]}" "${MON_Y[$c]}" "${MON_SCALE[$c]}" "$rr"
  done
}

# hypr_scale WIDTH HEIGHT SCALE -> the nearest scale Hyprland accepts: a multiple of 1/120 that divides both sides.
hypr_scale() {
  awk -v w="$1" -v h="$2" -v s="$3" 'BEGIN {
    base = int(s * 120 + 0.5)
    for (d = 0; d <= 30; d++) {
      n = base - d; if (n > 0 && (w * 120) % n == 0 && (h * 120) % n == 0) { printf "%g", n / 120; exit }
      n = base + d; if ((w * 120) % n == 0 && (h * 120) % n == 0) { printf "%g", n / 120; exit }
    }
    printf "%g", s }'
}

# --- Hyprland (Lua)
mon_hypr() {
  local c out
  echo "-- Written by fedora-noctalia-setup from your monitor layout (monitors.conf). Change it with \`monitors\`."
  for c in "${MON_ORDER[@]}"; do
    if [[ -n "${MON_INTERNAL[$c]}" ]]; then out=$c; else out="desc:${MON_NAME[$c]}"; fi
    if [[ -z "${MON_ON[$c]}" ]]; then printf 'hl.monitor({ output = "%s", disabled = true })\n' "$out"; continue; fi
    printf 'hl.monitor({ output = "%s", mode = "preferred", position = "%dx%d", scale = %s, transform = %d })\n' \
      "$out" "${MON_X[$c]}" "${MON_Y[$c]}" "$(hypr_scale "${MON_W[$c]}" "${MON_H[$c]}" "${MON_SCALE[$c]}")" \
      $((MON_ROT[$c] / 90))
  done
  echo 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 }) -- any other monitor'
  c=$(mon_internal)
  [[ -n "$c" && -n "${MON_ON[$c]}" && "$MON_LAPTOP_DOCKED" == off ]] || return 0
  cat <<EOF

-- Laptop panel off while an external monitor is connected or the lid is closed with one connected (the dock-watch of
-- the other compositors), back on when undocked. Runs on every plug event.
local panel = "$c"
local function docked(gone)
  for _, m in ipairs(hl.get_monitors()) do
    local n = m.name
    if n ~= gone and n ~= panel and not n:match("^FALLBACK") and not n:match("^HEADLESS") then return true end
  end
  return false
end
local function apply(gone)
  if docked(gone) then
    hl.monitor({ output = panel, disabled = true })
  else
    hl.monitor({ output = panel, disabled = false, mode = "preferred", position = "${MON_X[$c]}x${MON_Y[$c]}", scale = $(hypr_scale "${MON_W[$c]}" "${MON_H[$c]}" "${MON_SCALE[$c]}"), transform = $((MON_ROT[$c] / 90)) })
  end
end
hl.on("hyprland.start", function() apply() end)
hl.on("monitor.added", function() apply() end)
hl.on("monitor.removed", function(m) apply(m and m.name) end)
apply()
EOF
}

# write_monitors CONFIG_DIR: the layout for every chosen compositor. Only once you have a layout: without
# monitors.conf every compositor keeps its own automatic arrangement.
write_monitors() {
  [[ -f "$MONITORS_FILE" ]] || return 0
  mon_scan
  mon_load
  mon_layout
  if item_on umbriel; then mkdir -p "$1/umbriel"; mon_umbriel >"$1/umbriel/monitors.toml"; fi
  if item_on niri; then mkdir -p "$1/niri"; mon_niri >"$1/niri/monitors.kdl"; fi
  if item_on mango; then mkdir -p "$1/mango"; mon_mango >"$1/mango/monitors.conf"; fi
  if item_on hyprland; then mkdir -p "$1/hypr"; mon_hypr >"$1/hypr/monitors.lua"; fi
  return 0
}
