# shellcheck shell=bash
# Keybindings: one table (config/keybinds.tsv) plus your changes, written into each compositor's own syntax:
#   ~/.config/umbriel/keybinds.toml  ~/.config/niri/keybinds.kdl  ~/.config/mango/keybinds.conf  ~/.config/hypr/keybinds.lua
# The repo defaults of each compositor include that file. Your changes: ~/.config/fedora-noctalia-setup/keybinds.conf
# ("action=Keys" lines), edited by the installer's Keybindings page or the `keybinds` command.

KEYBINDS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fedora-noctalia-setup/keybinds.conf"
KB_MODS=(Super Ctrl Alt Shift)
# Named keys besides letters, digits and F1-F12.
KB_NAMED=" Return Space Escape Tab BackSpace Delete Insert Home End Page_Up Page_Down Left Right Up Down Print Period Comma
  Minus Plus Equal Slash Backslash Semicolon Apostrophe Grave BracketLeft BracketRight "

declare -gA KB_GROUP KB_LABEL KB_DEFAULT KB_KIND KB_ARG KB_FLAGS KB_KEY
KB_IDS=()

# kb_load [TABLE]: the table, then the saved changes, then KEYBIND_OVERRIDES ("id=Keys;id=Keys", from the TUI).
kb_load() {
  local id group label def kind arg flags pair
  KB_IDS=()
  while IFS='|' read -r id group label def kind arg flags; do
    [[ -z "$id" || "$id" == \#* ]] && continue
    KB_IDS+=("$id")
    KB_GROUP[$id]=$group KB_LABEL[$id]=$label KB_DEFAULT[$id]=$def KB_KIND[$id]=$kind KB_ARG[$id]=$arg KB_FLAGS[$id]=$flags
    KB_KEY[$id]=$def
  done <"${1:-$REPO_DIR/config/keybinds.tsv}"
  if [[ -f "$KEYBINDS_FILE" ]]; then
    while IFS='=' read -r id def; do
      [[ -n "${KB_LABEL[$id]:-}" && -n "$def" ]] && KB_KEY[$id]=$def
    done <"$KEYBINDS_FILE"
  fi
  local -a pairs
  IFS=';' read -ra pairs <<<"${KEYBIND_OVERRIDES:-}"
  for pair in "${pairs[@]}"; do
    id=${pair%%=*} def=${pair#*=}
    [[ -n "${KB_LABEL[$id]:-}" && -n "$def" ]] && KB_KEY[$id]=$def
  done
  return 0
}

# kb_normalize KEYS -> KEYS in the table's spelling (super+shift+w -> Super+Shift+W), or status 1 when invalid.
kb_normalize() {
  local -a parts
  local part key out="" m lower
  IFS='+' read -ra parts <<<"$1"
  ((${#parts[@]})) || return 1
  key=${parts[-1]}
  unset 'parts[-1]'
  for m in "${KB_MODS[@]}"; do
    for part in "${parts[@]}"; do
      lower=${part,,}
      case "$lower" in mod | win | meta) lower=super ;; control) lower=ctrl ;; esac
      if [[ "$lower" == "${m,,}" ]]; then out+="$m+"; continue 2; fi
    done
  done
  # Every modifier given must be one we know, and none twice.
  [[ "$(tr -cd '+' <<<"$out" | wc -c)" == "${#parts[@]}" ]] || return 1
  if [[ "$key" =~ ^[A-Za-z0-9]$ ]]; then
    key=${key^^}
  elif [[ "${key,,}" =~ ^f([1-9]|1[0-2])$ ]]; then
    key=${key^^}
  elif [[ "$key" == XF86* ]]; then
    :
  else
    for m in $KB_NAMED; do if [[ "${m,,}" == "${key,,}" ]]; then key=$m; break; fi; done
    [[ " $KB_NAMED " == *" $key "* ]] || return 1
  fi
  echo "$out$key"
}

# kb_conflict ID KEYS -> the id of another action already on KEYS, empty when free.
kb_conflict() {
  local id
  for id in "${KB_IDS[@]}"; do
    if [[ "$id" != "$1" && "${KB_KEY[$id]}" == "$2" ]]; then echo "$id"; return 0; fi
  done
}

# kb_split KEYS: KB_M (modifiers, space separated) and KB_K (the key).
kb_split() {
  KB_K=${1##*+} KB_M=""
  if [[ "$1" == *+* ]]; then KB_M=${1%+*} KB_M=${KB_M//+/ }; fi
}

# --- Umbriel (TOML): "Mod+Shift+W" = { action = "...", repeat = false }

kb_umbriel_action() {
  case "$1" in
    close) echo window-close ;; kill) echo window-kill ;; float) echo window-toggle-floating ;;
    maximize) echo window-toggle-maximize ;; fullscreen) echo window-toggle-fullscreen ;;
    focus-left) echo window-focus-or-output-left ;; focus-right) echo window-focus-or-output-right ;;
    focus-up) echo window-focus-up ;; focus-down) echo window-focus-down ;;
    move-left) echo window-move-or-output-left ;; move-right) echo window-move-or-output-right ;;
    move-up) echo window-move-up ;; move-down) echo window-move-down ;;
    cycle) echo window-focus-next ;; overview) echo overview-toggle ;; scratchpad) echo scratchpad-toggle ;;
    desk-[0-9]) echo "spawn ~/.config/umbriel/scripts/desks.sh focus ${1#desk-}" ;;
    to-desk-[0-9]) echo "window-move-to-workspace-silent ${1#to-desk-}" ;;
    desk-prev) echo "spawn ~/.config/umbriel/scripts/desks.sh step -1" ;;
    desk-next) echo "spawn ~/.config/umbriel/scripts/desks.sh step 1" ;;
    carry-prev) echo "spawn ~/.config/umbriel/scripts/desks.sh carry -1" ;;
    carry-next) echo "spawn ~/.config/umbriel/scripts/desks.sh carry 1" ;;
  esac
}

kb_umbriel() {
  local id action key opts
  echo "# Written by fedora-noctalia-setup from config/keybinds.tsv and your keybinds.conf. Change keys with \`keybinds\`."
  echo "[keybinds]"
  for id in "${KB_IDS[@]}"; do
    case "${KB_KIND[$id]}" in
      spawn) action="spawn ${KB_ARG[$id]}" ;;
      noctalia) action="spawn noctalia msg ${KB_ARG[$id]}" ;;
      wm) action=$(kb_umbriel_action "${KB_ARG[$id]}") ;;
    esac
    [[ -n "$action" ]] || continue
    kb_split "${KB_KEY[$id]}"
    key="${KB_M//Super/Mod}"
    key="${key// /+}${key:++}$KB_K"
    opts=""
    [[ " ${KB_FLAGS[$id]} " == *" repeat "* ]] || opts+=", repeat = false"
    [[ " ${KB_FLAGS[$id]} " == *" locked "* ]] && opts+=", allow_when_locked = true"
    printf '"%s" = { action = "%s"%s }   # %s\n' "$key" "$action" "$opts" "${KB_LABEL[$id]}"
  done
}

# --- niri (KDL): Mod+Shift+W repeat=false { action; }

kb_niri_action() {
  case "$1" in
    close | kill) echo "close-window" ;; float) echo "toggle-window-floating" ;; maximize) echo "maximize-column" ;;
    fullscreen) echo "fullscreen-window" ;;
    focus-left) echo "focus-column-left" ;; focus-right) echo "focus-column-right" ;;
    focus-up) echo "focus-window-up" ;; focus-down) echo "focus-window-down" ;;
    move-left) echo "move-column-left" ;; move-right) echo "move-column-right" ;;
    move-up) echo "move-window-up" ;; move-down) echo "move-window-down" ;;
    cycle) echo "focus-window-previous" ;; overview) echo "toggle-overview" ;;
    desk-[0-9]) echo "focus-workspace ${1#desk-}" ;; to-desk-[0-9]) echo "move-column-to-workspace ${1#to-desk-}" ;;
    desk-prev) echo "focus-workspace-up" ;; desk-next) echo "focus-workspace-down" ;;
    carry-prev) echo "move-column-to-workspace-up" ;; carry-next) echo "move-column-to-workspace-down" ;;
  esac
}

kb_niri() {
  local id action key opts
  echo "// Written by fedora-noctalia-setup from config/keybinds.tsv and your keybinds.conf. Change keys with \`keybinds\`."
  echo "binds {"
  for id in "${KB_IDS[@]}"; do
    case "${KB_KIND[$id]}" in
      spawn) action="spawn-sh \"${KB_ARG[$id]}\"" ;;
      noctalia) action="spawn-sh \"noctalia msg ${KB_ARG[$id]}\"" ;;
      wm) action=$(kb_niri_action "${KB_ARG[$id]}") ;;
    esac
    [[ -n "$action" ]] || continue
    kb_split "${KB_KEY[$id]}"
    key="${KB_M//Super/Mod}"
    key="${key// /+}${key:++}$KB_K"
    opts=""
    [[ " ${KB_FLAGS[$id]} " == *" repeat "* ]] || opts+=" repeat=false"
    [[ " ${KB_FLAGS[$id]} " == *" locked "* ]] && opts+=" allow-when-locked=true"
    printf '    %s%s { %s; }  // %s\n' "$key" "$opts" "$action" "${KB_LABEL[$id]}"
  done
  echo "}"
}

# --- MangoWC: bind=SUPER+SHIFT,w,spawn,cmd

kb_mango_action() {
  case "$1" in
    close) echo killclient ;; kill) echo "killclient,force" ;; float) echo togglefloating ;;
    maximize) echo togglemaximizescreen ;; fullscreen) echo togglefullscreen ;;
    focus-left | focus-right | focus-up | focus-down) echo "focusdir,${1#focus-}" ;;
    move-left | move-right | move-up | move-down) echo "exchange_client,${1#move-}" ;;
    cycle) echo "focusstack,next" ;; overview) echo toggleoverview ;; scratchpad) echo toggle_scratchpad ;;
    desk-[0-9]) echo "view,${1#desk-},0" ;; to-desk-[0-9]) echo "tag,${1#to-desk-},0" ;;
    desk-prev) echo "viewtoleft,0" ;; desk-next) echo "viewtoright,0" ;;
    carry-prev) echo "tagtoleft,0" ;; carry-next) echo "tagtoright,0" ;;
  esac
}

kb_mango_key() {
  case "$1" in
    [A-Z]) echo "${1,,}" ;;
    Space | Period | Comma | Minus | Plus | Equal | Slash | Backslash | Semicolon | Apostrophe | Grave) echo "${1,,}" ;;
    *) echo "$1" ;;
  esac
}

kb_mango() {
  local id action mods bind
  echo "# Written by fedora-noctalia-setup from config/keybinds.tsv and your keybinds.conf. Change keys with \`keybinds\`."
  for id in "${KB_IDS[@]}"; do
    case "${KB_KIND[$id]}" in
      spawn) action="spawn,${KB_ARG[$id]}" ;;
      noctalia) action="spawn,noctalia msg ${KB_ARG[$id]}" ;;
      wm) action=$(kb_mango_action "${KB_ARG[$id]}") ;;
    esac
    [[ -n "$action" ]] || continue
    kb_split "${KB_KEY[$id]}"
    mods=${KB_M^^}
    mods=${mods//CTRL/CTRL}
    mods=${mods// /+}
    bind=bind
    [[ " ${KB_FLAGS[$id]} " == *" locked "* ]] && bind=bindl
    printf '%s=%s,%s,%s\n' "$bind" "${mods:-NONE}" "$(kb_mango_key "$KB_K")" "$action"
  done
}

# --- Hyprland (Lua): hl.bind("SUPER + SHIFT + W", action, opts)

kb_hypr_action() {
  case "$1" in
    close) echo 'hl.dsp.window.close()' ;; kill) echo 'hl.dsp.exec_cmd("hyprctl kill")' ;;
    float) echo 'hl.dsp.window.float({ action = "toggle" })' ;;
    maximize) echo 'hl.dsp.window.fullscreen({ mode = "maximized" })' ;;
    fullscreen) echo 'hl.dsp.window.fullscreen({ mode = "fullscreen" })' ;;
    focus-left | focus-right | focus-up | focus-down) echo "hl.dsp.focus({ direction = \"${1#focus-}\" })" ;;
    move-left) echo 'hl.dsp.window.move({ direction = "l" })' ;; move-right) echo 'hl.dsp.window.move({ direction = "r" })' ;;
    move-up) echo 'hl.dsp.window.move({ direction = "u" })' ;; move-down) echo 'hl.dsp.window.move({ direction = "d" })' ;;
    cycle) echo 'hl.dsp.window.cycle_next()' ;;
    scratchpad) echo 'hl.dsp.workspace.toggle_special("scratchpad")' ;;
    desk-[0-9]) echo "function() desks.focus(${1#desk-}) end" ;;
    to-desk-[0-9]) echo "function() desks.move_to(${1#to-desk-}) end" ;;
    desk-prev) echo 'function() desks.go(-1) end' ;; desk-next) echo 'function() desks.go(1) end' ;;
    carry-prev) echo 'function() desks.carry(-1) end' ;; carry-next) echo 'function() desks.carry(1) end' ;;
  esac
}

kb_hypr_key() {
  local mods key=$2
  mods=${1^^}
  mods=${mods//CTRL/CONTROL}
  # Digits by keycode (1 = code:10), so they work on QWERTZ and AZERTY too.
  if [[ "$key" =~ ^[0-9]$ ]]; then key="code:$((key == 0 ? 19 : 9 + key))"; fi
  case "$key" in Period | Comma | Minus | Plus | Equal | Slash | Backslash | Semicolon | Apostrophe | Grave) key=${key,,} ;; esac
  if [[ -n "$mods" ]]; then echo "${mods// / + } + $key"; else echo "$key"; fi
}

kb_hypr() {
  local id action opts
  echo "-- Written by fedora-noctalia-setup from config/keybinds.tsv and your keybinds.conf. Change keys with \`keybinds\`."
  echo "local desks = require(\"$1/config/hypr/desks.lua\")"
  echo 'local function run(cmd) return hl.dsp.exec_cmd("uwsm app -- " .. cmd) end'
  for id in "${KB_IDS[@]}"; do
    case "${KB_KIND[$id]}" in
      spawn) action="run(\"${KB_ARG[$id]}\")" ;;
      noctalia) action="hl.dsp.exec_cmd(\"noctalia msg ${KB_ARG[$id]}\")" ;;
      wm) action=$(kb_hypr_action "${KB_ARG[$id]}") ;;
    esac
    [[ -n "$action" ]] || continue
    kb_split "${KB_KEY[$id]}"
    opts=""
    if [[ " ${KB_FLAGS[$id]} " == *" locked "* && " ${KB_FLAGS[$id]} " == *" repeat "* ]]; then opts=", { locked = true, repeating = true }"
    elif [[ " ${KB_FLAGS[$id]} " == *" locked "* ]]; then opts=", { locked = true }"
    elif [[ " ${KB_FLAGS[$id]} " == *" repeat "* ]]; then opts=", { repeating = true }"; fi
    printf 'hl.bind("%s", %s%s) -- %s\n' "$(kb_hypr_key "$KB_M" "$KB_K")" "$action" "$opts" "${KB_LABEL[$id]}"
  done
}

# save_keybinds: the keys that differ from the table, into keybinds.conf.
save_keybinds() {
  local id
  mkdir -p "$(dirname "$KEYBINDS_FILE")"
  {
    echo "# Your keybindings, as \"action=Keys\". Only what differs from the defaults; \`keybinds\` lists the actions."
    for id in "${KB_IDS[@]}"; do
      if [[ "${KB_KEY[$id]}" != "${KB_DEFAULT[$id]}" ]]; then echo "$id=${KB_KEY[$id]}"; fi
    done
  } >"$KEYBINDS_FILE"
}

# write_keybinds CONFIG_DIR: the bindings for every chosen compositor.
write_keybinds() {
  kb_load
  if [[ -n "${KEYBIND_OVERRIDES:-}" ]]; then save_keybinds; fi
  if item_on umbriel; then mkdir -p "$1/umbriel"; kb_umbriel >"$1/umbriel/keybinds.toml"; fi
  if item_on niri; then mkdir -p "$1/niri"; kb_niri >"$1/niri/keybinds.kdl"; fi
  if item_on mango; then mkdir -p "$1/mango"; kb_mango >"$1/mango/keybinds.conf"; fi
  if item_on hyprland; then mkdir -p "$1/hypr"; kb_hypr "$REPO_DIR" >"$1/hypr/keybinds.lua"; fi
  return 0
}
