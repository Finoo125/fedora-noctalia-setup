# shellcheck shell=bash
# The full-screen installer: the steps on the left, the current step on the right, the keys at the bottom.
# Plain bash and escape codes, so it runs on a fresh Minimal Install, in a terminal emulator and on the Linux console.
# Screens draw into TUI_BUF and tui_flush prints it in one go, so tests can render a screen at a fixed size.

E=$'\e'
TUI_SB=26 # sidebar width, its border included

# The desktop's Ayu colors; the 16-color codes are for the Linux console and terminals without 256 colors.
declare -gA TUI_HEX=([page]=0B0E14 [surface]=11151C [line]=273747 [fg]=BFBDB6 [bright]=E6E1CF [muted]=8A9199
  [accent]=E6B450 [green]=AAD94C [cyan]=39BAE6 [red]=F07178 [log]=070A0F)
declare -gA TUI_16FG=([page]=30 [surface]=30 [line]=90 [fg]=37 [bright]=97 [muted]=90 [accent]=93 [green]=92
  [cyan]=96 [red]=91 [log]=30)
declare -gA TUI_16BG=([page]=49 [surface]=49 [line]=100 [fg]=47 [bright]=107 [muted]=100 [accent]=43 [green]=42
  [cyan]=46 [red]=41 [log]=49)
declare -gA TF TB

# tui_color_mode TERM COLORTERM -> truecolor | 256 | 16
tui_color_mode() {
  case "$2" in truecolor | 24bit) echo truecolor; return ;; esac
  case "$1" in
    linux | vt* | dumb | "") echo 16 ;;
    *256color* | xterm-kitty | xterm-ghostty | foot* | alacritty | wezterm) echo 256 ;;
    *) echo 16 ;;
  esac
}

# tui_hex256 RRGGBB -> the nearest xterm-256 color index.
tui_hex256() {
  local r=$((16#${1:0:2})) g=$((16#${1:2:2})) b=$((16#${1:4:2}))
  if ((r == g && g == b)); then
    if ((r < 8)); then echo 16; elif ((r > 248)); then echo 231; else echo $(((r - 8) * 24 / 247 + 232)); fi
    return
  fi
  echo $((16 + 36 * ((r * 5 + 127) / 255) + 6 * ((g * 5 + 127) / 255) + (b * 5 + 127) / 255))
}

# tui_colors MODE: fills TF/TB (foreground/background escape per color name).
tui_colors() {
  local name hex r g b
  for name in "${!TUI_HEX[@]}"; do
    hex=${TUI_HEX[$name]}
    case "$1" in
      truecolor)
        r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
        TF[$name]="${E}[38;2;$r;$g;${b}m" TB[$name]="${E}[48;2;$r;$g;${b}m"
        ;;
      256) TF[$name]="${E}[38;5;$(tui_hex256 "$hex")m" TB[$name]="${E}[48;5;$(tui_hex256 "$hex")m" ;;
      *) TF[$name]="${E}[${TUI_16FG[$name]}m" TB[$name]="${E}[${TUI_16BG[$name]}m" ;;
    esac
  done
}

# tui_glyphs TERM: symbols; the Linux console's font lacks most of them, so it gets ASCII.
tui_glyphs() {
  if [[ "$1" == linux ]]; then
    G_DONE='+' G_CUR='>' G_TODO='-' G_RUN='*' G_FAIL='x' G_SKIP='-' G_LOCK='#' G_V='|' G_H='-' G_TL='+' G_TR='+'
    G_BL='+' G_BR='+' G_FULL='#' G_EMPTY='.' G_DOT='-' G_PTR='>' G_UP='^' G_DOWN='v' G_STAR='*'
  else
    G_DONE='✓' G_CUR='●' G_TODO='○' G_RUN='◐' G_FAIL='✗' G_SKIP='–' G_LOCK='■' G_V='│' G_H='─' G_TL='┌' G_TR='┐'
    G_BL='└' G_BR='┘' G_FULL='█' G_EMPTY='░' G_DOT='·' G_PTR='▸' G_UP='↑' G_DOWN='↓' G_STAR='★'
  fi
}

# tui_wrap WIDTH TEXT -> TEXT word-wrapped to WIDTH characters, one line per output line.
tui_wrap() {
  local w=$1 line="" word
  local -a words
  read -ra words <<<"$2"
  for word in "${words[@]}"; do
    if [[ -z "$line" ]]; then
      line=$word
    elif ((${#line} + 1 + ${#word} <= w)); then
      line+=" $word"
    else
      printf '%s\n' "$line"
      line=$word
    fi
  done
  if [[ -n "$line" ]]; then printf '%s\n' "$line"; fi
}

# --- Drawing primitives. A style is "fg[,bg[,bold]]" by color name; the background defaults to the page.

tui_style() {
  local fg bg bold
  IFS=, read -r fg bg bold <<<"$1"
  TUI_S="${E}[0m${TF[${fg:-fg}]}${TB[${bg:-page}]}"
  if [[ -n "$bold" ]]; then TUI_S+="${E}[1m"; fi
}

# tui_put ROW COL MAXWIDTH STYLE TEXT: TEXT cut to MAXWIDTH characters.
tui_put() {
  (($3 > 0)) || return 0
  tui_style "$4"
  TUI_BUF+="${E}[$1;$2H$TUI_S${5:0:$3}"
}

# tui_fill ROW BG: paints the whole row.
tui_fill() { TUI_BUF+="${E}[$1;1H${E}[0m${TB[$2]}${E}[K"; }

tui_size() {
  local size
  size=$(stty size 2>/dev/null || echo "24 80")
  TUI_H=${size% *} TUI_W=${size#* }
  TUI_C0=$((TUI_SB + 3)) TUI_CW=$((TUI_W - TUI_SB - 4)) TUI_R0=3 TUI_R1=$((TUI_H - 2))
}

tui_frame_begin() {
  local r
  TUI_BUF="${E}[0m"
  for ((r = 1; r <= TUI_H; r++)); do tui_fill "$r" page; done
}

tui_flush() { printf '%s' "$TUI_BUF${E}[0m"; }

# tui_topbar RIGHT: the name, the system and RIGHT (step counter, clock).
tui_topbar() {
  tui_fill 1 surface
  tui_put 1 2 21 "accent,surface,b" "fedora-noctalia-setup"
  tui_put 1 23 $((TUI_W - 26 - ${#1})) "muted,surface" " $G_DOT ${TUI_SYSTEM:-Fedora} $G_DOT Umbriel + Noctalia"
  tui_put 1 $((TUI_W - ${#1})) "${#1}" "muted,surface" "$1"
}

# tui_sidebar LINES...: each "style|text", from row 3; plus the border.
tui_sidebar() {
  local r=$TUI_R0 entry
  for ((r = 2; r < TUI_H; r++)); do tui_put "$r" "$TUI_SB" 1 line "$G_V"; done
  r=$TUI_R0
  for entry in "$@"; do
    tui_put "$r" 3 $((TUI_SB - 4)) "${entry%%|*}" "${entry#*|}"
    r=$((r + 1))
  done
}

# tui_wizard_sidebar CURRENT: the six wizard steps, CURRENT (0-5) highlighted.
tui_wizard_sidebar() {
  local i
  local -a lines=()
  for i in "${!TUI_WIZARD[@]}"; do
    if ((i < $1)); then
      lines+=("green|$G_DONE ${TUI_WIZARD[i]}")
    elif ((i == $1)); then
      lines+=("accent,,b|$G_CUR ${TUI_WIZARD[i]}")
    else
      lines+=("muted|$G_TODO ${TUI_WIZARD[i]}")
    fi
  done
  tui_sidebar "${lines[@]}"
}

# tui_footer RIGHT PAIRS...: "key|what it does" pairs on the left, RIGHT on the right.
tui_footer() {
  local col=2 pair key what right=$1
  shift
  tui_fill "$TUI_H" surface
  for pair in "$@"; do
    key=${pair%%|*} what=${pair#*|}
    tui_put "$TUI_H" "$col" 20 "fg,surface,b" "$key"
    col=$((col + ${#key} + 1))
    tui_put "$TUI_H" "$col" 30 "muted,surface" "$what"
    col=$((col + ${#what} + 3))
  done
  if ((${#right} < TUI_W - col - 2)); then tui_put "$TUI_H" $((TUI_W - ${#right})) "${#right}" "muted,surface" "$right"; fi
}

# Content area: tui_text STYLE TEXT writes wrapped text at TUI_ROW and moves it down; tui_gap adds a blank line.
tui_text() {
  local line
  while IFS= read -r line; do
    ((TUI_ROW <= ${TUI_RLIMIT:-$TUI_R1})) || return 0
    tui_put "$TUI_ROW" "${TUI_COL:-$TUI_C0}" "${TUI_TW:-$TUI_CW}" "$1" "$line"
    TUI_ROW=$((TUI_ROW + 1))
  done < <(tui_wrap "${TUI_TW:-$TUI_CW}" "$2")
}
tui_gap() { TUI_ROW=$((TUI_ROW + 1)) || true; }

# tui_mark ROW COL STYLE MARK TEXT: a colored status mark, then TEXT.
tui_mark() {
  tui_put "$1" "$2" 2 "$3" "$4"
  tui_put "$1" $(($2 + 2)) $((TUI_CW - ($2 - TUI_C0) - 2)) fg "$5"
}

# tui_buttons ROW SELECTED LABELS...: the selected one in the accent color.
tui_buttons() {
  local row=$1 sel=$2 col=$TUI_C0 i=0 label
  shift 2
  for label in "$@"; do
    if ((i == sel)); then
      tui_put "$row" "$col" $((${#label} + 4)) "page,accent,b" "  $label  "
    else
      tui_put "$row" "$col" $((${#label} + 4)) "fg" "[ $label ]"
    fi
    col=$((col + ${#label} + 6))
    i=$((i + 1))
  done
}

# tui_box ROW COL WIDTH HEIGHT TITLE_STYLE TITLE: a frame in the line color with a title on its top edge.
tui_box() {
  local r inner=$(($3 - 2))
  tui_put "$1" "$2" "$3" line "$G_TL$(tui_repeat "$G_H" "$inner")$G_TR"
  for ((r = $1 + 1; r < $1 + $4 - 1; r++)); do
    tui_put "$r" "$2" 1 line "$G_V"
    tui_put "$r" $(($2 + $3 - 1)) 1 line "$G_V"
  done
  tui_put $(($1 + $4 - 1)) "$2" "$3" line "$G_BL$(tui_repeat "$G_H" "$inner")$G_BR"
  if [[ -n "$6" ]]; then tui_put "$1" $(($2 + 2)) $((inner - 2)) "$5" " $6 "; fi
}

# tui_repeat CHAR COUNT -> CHAR COUNT times.
tui_repeat() {
  local out="" i
  for ((i = 0; i < $2; i++)); do out+=$1; done
  printf '%s' "$out"
}

# tui_bar ROW COL WIDTH DONE TOTAL: a progress bar.
tui_bar() {
  local full=0
  (($5 > 0)) && full=$(($3 * $4 / $5))
  ((full > $3)) && full=$3
  tui_put "$1" "$2" "$full" accent "$(tui_repeat "$G_FULL" "$full")"
  tui_put "$1" $(($2 + full)) $(($3 - full)) line "$(tui_repeat "$G_EMPTY" $(($3 - full)))"
}

# tui_read_key [TIMEOUT]: KEY = up down left right home end pgup pgdn enter space tab back esc q other, or "" on timeout.
tui_read_key() {
  local k="" rest=""
  KEY=""
  if ! IFS= read -rsn1 -t "${1:-3600}" k; then return 0; fi
  case "$k" in
    "$E")
      IFS= read -rsn2 -t 0.05 rest || true
      case "$rest" in
        '[A') KEY=up ;; '[B') KEY=down ;; '[C') KEY=right ;; '[D') KEY=left ;; '[H') KEY=home ;; '[F') KEY=end ;;
        '[5' | '[6')
          IFS= read -rsn1 -t 0.05 k || true
          if [[ "$rest" == '[5' ]]; then KEY=pgup; else KEY=pgdn; fi
          ;;
        '') KEY=esc ;;
        *) KEY=other ;;
      esac
      ;;
    '') KEY=enter ;;
    ' ') KEY=space ;;
    $'\t') KEY=tab ;;
    $'\x7f' | $'\b') KEY=back ;;
    q | Q) KEY=q ;;
    d | D) KEY=d ;;
    k) KEY=up ;;
    j) KEY=down ;;
    *) KEY=other ;;
  esac
}

tui_start() {
  TUI_STTY=$(stty -g 2>/dev/null || true)
  stty -echo -icanon 2>/dev/null || true
  printf '%s' "${E}[?1049h${E}[?25l"
  trap 'tui_stop; exit 130' INT TERM
}

tui_stop() {
  printf '%s' "${E}[0m${E}[?25h${E}[?1049l"
  if [[ -n "${TUI_STTY:-}" ]]; then stty "$TUI_STTY" 2>/dev/null || true; fi
  trap - INT TERM
}

# --- What the machine has, for the welcome screen and the choices' defaults.

tui_detect() {
  local id version dm kind
  # shellcheck source=/dev/null
  id=$(. /etc/os-release && echo "${NAME:-Linux}") version=$(. /etc/os-release && echo "${VERSION_ID:-}")
  TUI_SYSTEM="$id $version"
  TUI_LOCALE=$(. /etc/locale.conf 2>/dev/null; echo "${LANG:-C.UTF-8}")
  TUI_LAYOUT=$(keyboard_layout "$XKB_CONF")
  TUI_TZ=$(timedatectl show -p Timezone --value 2>/dev/null || echo UTC)
  TUI_ROOT_FS=$(findmnt -no FSTYPE / 2>/dev/null || echo unknown)
  TUI_HOME_FS=$(findmnt -no FSTYPE /home 2>/dev/null || echo unknown)
  if compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then TUI_LAPTOP=1; else TUI_LAPTOP=""; fi
  TUI_GPU=unknown
  if have lspci; then
    kind=$(nvidia_classify "$(lspci -d ::03xx)")
    TUI_GPU=$kind
  fi
  TUI_DM=""
  for dm in greetd gdm sddm plasmalogin lightdm; do
    if systemctl is-enabled -q "$dm" 2>/dev/null; then TUI_DM=$dm; break; fi
  done
  TUI_MIGRATE=""
  if [[ ! -f "$STATE_DIR/fedora-hyprland-migrated" ]] &&
    [[ -d "$OLD_STATE_DIR" || -d "$HOME/.local/share/fedora-hyprland" ]]; then TUI_MIGRATE=1; fi
}

# The wizard's pages: welcome, one per software menu, extras, look, review; the sidebar adds Install and Done.
tui_pages() {
  local menu
  TUI_PAGES=(welcome) TUI_WIZARD=(Welcome)
  for menu in "${CATEGORIES[@]}"; do
    TUI_PAGES+=("menu:${menu%%|*}")
    TUI_WIZARD+=("${menu#*|}")
  done
  TUI_PAGES+=(extras look review)
  TUI_WIZARD+=(Extras Look Review Install Done)
}

# tui_step INDEX -> "step N of M" for the top bar.
tui_step() { echo "step $(($1 + 1)) of ${#TUI_WIZARD[@]}"; }

# The extras: "id|label|what it does". They are questions, not apps.
TUI_EXTRAS=("nvidia|NVIDIA driver|RPM Fusion's driver for RTX 20 to RTX 50 cards: open kernel modules, CUDA, NVENC. With Secure Boot you set a one-time password."
  "fingerprint|Fingerprint login|Unlock sudo, the login and the lock screen with a finger. Enrolled after the install, when this window closes."
  "home-snapshots|Hourly snapshots of /home|Every hour, kept 7 days, so a deleted file can be restored. No backup: Pika Backup copies to another drive."
  "grub-btrfs|Snapshots in the boot menu|A Fedora snapshots entry in the boot menu, to start the system as it was before an update.")
declare -gA TUI_ON TUI_OFF_WHY TUI_DEFAULT
ROLES=(terminal browser files editor)

# tui_defaults: every choice's starting value: saved apps, remembered "no"s, what the hardware allows.
tui_defaults() {
  local id key role
  for id in "${CAT_IDS[@]}"; do if item_on "$id"; then TUI_ON[$id]=1; else TUI_ON[$id]=""; fi; done
  for role in "${ROLES[@]}"; do TUI_DEFAULT[$role]=$(default_for "$role"); done
  for key in fingerprint home-snapshots grub-btrfs nvidia; do
    if [[ -f "$STATE_DIR/declined-$key" ]]; then TUI_ON[$key]=""; else TUI_ON[$key]=1; fi
  done
  case "$TUI_GPU" in
    none) TUI_OFF_WHY[nvidia]="no NVIDIA card" ;;
    legacy) TUI_OFF_WHY[nvidia]="card too old" ;;
    unknown) TUI_OFF_WHY[nvidia]="checked later" ;;
  esac
  if rpm -q akmod-nvidia >/dev/null 2>&1; then TUI_OFF_WHY[nvidia]="installed"; fi
  if [[ -z "$TUI_LAPTOP" ]]; then TUI_ON[fingerprint]=""; fi
  [[ "$TUI_HOME_FS" == btrfs ]] || TUI_OFF_WHY[home-snapshots]="/home not on btrfs"
  [[ -d /home/.snapshots ]] && TUI_OFF_WHY[home-snapshots]="already on"
  [[ "$TUI_ROOT_FS" == btrfs ]] || TUI_OFF_WHY[grub-btrfs]="/ not on btrfs"
  [[ -f "$STATE_DIR/grub-btrfs-version" ]] && TUI_OFF_WHY[grub-btrfs]="already on"
  for key in "${!TUI_OFF_WHY[@]}"; do TUI_ON[$key]=""; done
  PRESET_CHOICE=$(basename "$(readlink "$HOME/.config/noctalia/30-preset.toml" 2>/dev/null || echo waterfall.toml)" .toml)
}

# tui_sync: SOFTWARE_ITEMS and DEFAULT_<ROLE> from the ticks. A default that was unticked moves to the first
# ticked app with that role.
tui_sync() {
  local id role var
  SOFTWARE_ITEMS=""
  for id in "${CAT_IDS[@]}"; do
    if [[ -n "${TUI_ON[$id]:-}" ]]; then SOFTWARE_ITEMS+="${SOFTWARE_ITEMS:+ }$id"; fi
  done
  for role in "${ROLES[@]}"; do
    if [[ -z "${TUI_ON[${TUI_DEFAULT[$role]:-none}]:-}" ]]; then
      TUI_DEFAULT[$role]=""
      for id in "${CAT_IDS[@]}"; do
        if [[ "${CAT_ROLE[$id]}" == "$role" && -n "${TUI_ON[$id]:-}" ]]; then TUI_DEFAULT[$role]=$id; break; fi
      done
    fi
    var="DEFAULT_${role^^}"
    printf -v "$var" '%s' "${TUI_DEFAULT[$role]}"
  done
}

# tui_source_label ID -> where an app comes from, in a word or two.
tui_source_label() {
  case "${CAT_SOURCE[$1]}" in
    dnf) echo Fedora ;;
    rpmfusion) echo "RPM Fusion" ;;
    terra) echo Terra ;;
    flatpak) echo Flathub ;;
    script) echo download ;;
    repo:vscode | repo:edge) echo Microsoft ;;
    repo:chrome) echo Google ;;
    repo:docker) echo Docker ;;
    repo:brave) echo Brave ;;
    repo:vivaldi) echo Vivaldi ;;
    *) echo "${CAT_SOURCE[$1]}" ;;
  esac
}

# tui_repo_label NAME -> a vendor repo's name for people.
tui_repo_label() {
  case "$1" in
    vscode) echo "VS Code" ;; edge) echo "Microsoft Edge" ;; chrome) echo "Google Chrome" ;;
    docker) echo Docker ;; brave) echo Brave ;; vivaldi) echo Vivaldi ;; *) echo "$1" ;;
  esac
}

# tui_page_ids -> TUI_IDS: the rows of the current menu or extras page.
tui_page_ids() {
  local entry
  TUI_IDS=()
  case "${TUI_PAGES[TUI_PAGE]}" in
    menu:*) mapfile -t TUI_IDS < <(catalog_ids "${TUI_PAGES[TUI_PAGE]#menu:}") ;;
    extras) for entry in "${TUI_EXTRAS[@]}"; do TUI_IDS+=("${entry%%|*}"); done ;;
  esac
}

# tui_extra ID FIELD -> label or about of an extra.
tui_extra() {
  local entry id label about
  for entry in "${TUI_EXTRAS[@]}"; do
    IFS='|' read -r id label about <<<"$entry"
    if [[ "$id" == "$1" ]]; then
      if [[ "$2" == label ]]; then echo "$label"; else echo "$about"; fi
    fi
  done
}

# --- Screens. Each tui_screen_* draws one frame from the current state.

tui_screen_small() {
  TUI_BUF="${E}[0m${E}[2J${E}[H"
  TUI_BUF+="Make the window at least 80x24 (it is ${TUI_W}x${TUI_H}). Esc quits."
}

# tui_found STYLE MARK TEXT: one "What I found" line at TUI_ROW.
tui_found() {
  tui_mark "$TUI_ROW" "$TUI_C0" "$1" "$2" "$3"
  TUI_ROW=$((TUI_ROW + 1))
}

tui_screen_welcome() {
  tui_frame_begin
  tui_topbar "$(tui_step 0)"
  tui_wizard_sidebar 0
  TUI_ROW=$TUI_R0
  tui_text "bright,,b" "Welcome"
  tui_text fg "This turns Fedora into a Noctalia desktop: Umbriel, the Noctalia shell, its login screen and Luciole, with KDE Plasma as a fallback session."
  tui_gap
  tui_text muted "What I found"
  tui_found green "$G_DONE" "$TUI_SYSTEM, online"
  if [[ "$TUI_ROOT_FS" == btrfs ]]; then
    tui_found green "$G_DONE" "/ on btrfs, so snapshots before every update"
  else
    tui_found accent "!" "/ is $TUI_ROOT_FS, so no snapshots"
  fi
  tui_found cyan "i" "$TUI_LOCALE $G_DOT keyboard $TUI_LAYOUT $G_DOT $TUI_TZ"
  case "$TUI_GPU" in
    modern | hybrid) tui_found cyan "i" "NVIDIA card found${TUI_LAPTOP:+ in a laptop}" ;;
    *) tui_found cyan "i" "${TUI_LAPTOP:+Laptop, }no supported NVIDIA card" ;;
  esac
  tui_found cyan "i" "Login screen: ${TUI_DM:-none yet}, the Noctalia greeter takes over"
  tui_gap
  if [[ -n "$TUI_MIGRATE" ]]; then
    tui_box "$TUI_ROW" "$TUI_C0" "$TUI_CW" 4 "accent,,b" "fedora-hyprland found"
    TUI_COL=$((TUI_C0 + 2)) TUI_TW=$((TUI_CW - 4)) TUI_ROW=$((TUI_ROW + 1))
    tui_text fg "Moved over once: Hyprland and its COPR go; your looks, answers and monitors stay."
    TUI_COL="" TUI_TW=""
  fi
  tui_buttons $((TUI_R1)) "$TUI_BTN" "Continue" "Quit"
  tui_footer "nothing changes before Install now" "Enter|press" "Tab|next button" "Esc|quit"
}

# tui_screen_list: a menu or the extras: ticks on the left (scrolling), the highlighted row's details.
tui_screen_list() {
  local i id r mark star style role src label off wide listw top bottom rows dcol dw roles="" page_title
  tui_page_ids
  page_title=${TUI_WIZARD[TUI_PAGE]}
  tui_frame_begin
  tui_topbar "$(tui_step "$TUI_PAGE")"
  tui_wizard_sidebar "$TUI_PAGE"
  for id in "${TUI_IDS[@]}"; do
    role=${CAT_ROLE[$id]:-}
    if [[ -n "$role" && " $roles " != *" $role "* ]]; then roles+="${roles:+ }$role"; fi
  done
  if [[ -n "$roles" ]]; then
    tui_put "$TUI_R0" "$TUI_C0" "$TUI_CW" muted "$page_title: tick any. $G_STAR = the default ${roles// /, } (D)."
  elif [[ "${TUI_PAGES[TUI_PAGE]}" == extras ]]; then
    tui_put "$TUI_R0" "$TUI_C0" "$TUI_CW" muted "Extras: things to set up besides the apps."
  else
    tui_put "$TUI_R0" "$TUI_C0" "$TUI_CW" muted "$page_title: tick any."
  fi
  wide=0
  if ((TUI_CW >= 64)); then wide=1; fi
  top=$((TUI_R0 + 2))
  if ((wide)); then
    listw=$((TUI_CW >= 84 ? 40 : 34)) bottom=$TUI_R1
  else
    listw=$TUI_CW bottom=$((TUI_R1 - 5))
  fi
  rows=$((bottom - top + 1))
  ((TUI_SEL < TUI_TOP)) && TUI_TOP=$TUI_SEL
  ((TUI_SEL >= TUI_TOP + rows)) && TUI_TOP=$((TUI_SEL - rows + 1))
  r=$top
  for ((i = TUI_TOP; i < ${#TUI_IDS[@]} && r <= bottom; i++)); do
    id=${TUI_IDS[i]}
    mark=" " star=" "
    if [[ -n "${TUI_ON[$id]:-}" ]]; then mark=x; fi
    role=${CAT_ROLE[$id]:-}
    if [[ -n "$role" && "${TUI_DEFAULT[$role]:-}" == "$id" ]]; then star=$G_STAR; fi
    off=${TUI_OFF_WHY[$id]:-}
    if [[ -n "${CAT_LABEL[$id]:-}" ]]; then label=${CAT_LABEL[$id]} src=$(tui_source_label "$id"); else label=$(tui_extra "$id" label) src=$off; fi
    if ((i == TUI_SEL)); then style="page,accent,b"; elif [[ -n "$off" ]]; then style=muted; else style="fg"; fi
    tui_put "$r" "$TUI_C0" "$listw" "$style" "$(printf '[%s] %s %-*s' "$mark" "$star" $((listw - 6)) "$label")"
    tui_put "$r" $((TUI_C0 + listw - ${#src})) "${#src}" "${style/fg/muted}" "$src"
    r=$((r + 1))
  done
  if ((TUI_TOP > 0)); then tui_put $((top - 1)) $((TUI_C0 + listw - 6)) 6 muted "$G_UP more"; fi
  if ((TUI_TOP + rows < ${#TUI_IDS[@]})); then tui_put $((bottom + 1)) $((TUI_C0 + listw - 6)) 6 muted "$G_DOWN more"; fi
  # Details of the highlighted row.
  id=${TUI_IDS[TUI_SEL]}
  if ((wide)); then
    dcol=$((TUI_C0 + listw + 3)) dw=$((TUI_CW - listw - 3)) TUI_ROW=$top
  else
    dcol=$TUI_C0 dw=$TUI_CW TUI_ROW=$((bottom + 2))
  fi
  TUI_COL=$dcol TUI_TW=$dw
  if [[ -n "${CAT_LABEL[$id]:-}" ]]; then
    tui_text "bright,,b" "${CAT_LABEL[$id]}"
    tui_text fg "${CAT_ABOUT[$id]}"
    if ((wide)); then
      tui_gap
      tui_text muted "from $(tui_source_label "$id")"
      case "${CAT_SOURCE[$id]}" in
        script) ;;
        *) tui_text cyan "${CAT_PACKAGES[$id]}" ;;
      esac
      role=${CAT_ROLE[$id]:-}
      if [[ -n "$role" ]]; then
        tui_gap
        if [[ "${TUI_DEFAULT[$role]:-}" == "$id" ]]; then
          tui_text accent "$G_STAR the default $role"
        else
          tui_text muted "D makes it the default $role."
        fi
      fi
    fi
  else
    tui_text "bright,,b" "$(tui_extra "$id" label)"
    tui_text fg "$(tui_extra "$id" about)"
  fi
  TUI_COL="" TUI_TW=""
  if [[ -n "$roles" ]]; then
    tui_footer "" "$G_UP$G_DOWN|move" "Space|tick" "D|default" "Enter|next" "Backspace|back" "Esc|quit"
  else
    tui_footer "" "$G_UP$G_DOWN|move" "Space|tick" "Enter|next" "Backspace|back" "Esc|quit"
  fi
}

# Presets: TUI_PRESETS=(name...), TUI_PRESET_DESC[name]=description; "off" is the plain look.
tui_load_presets() {
  local mark name desc
  TUI_PRESETS=()
  declare -gA TUI_PRESET_DESC=()
  while read -r mark name desc; do
    TUI_PRESETS+=("$name")
    TUI_PRESET_DESC[$name]=$desc
  done < <("$REPO_DIR/bin/noctalia-preset" 2>/dev/null | sed 's/^ /-/')
  TUI_PRESETS+=(off)
  TUI_PRESET_DESC[off]="no look: Noctalia's Ayu palette and the first wallpaper of the list."
}

tui_screen_look() {
  local i name r=$TUI_R0 style mark
  tui_frame_begin
  tui_topbar "$(tui_step "$TUI_PAGE")"
  tui_wizard_sidebar "$TUI_PAGE"
  tui_put "$r" "$TUI_C0" "$TUI_CW" muted "Choose a look. Switch later with noctalia-preset."
  r=$((r + 2))
  for i in "${!TUI_PRESETS[@]}"; do
    name=${TUI_PRESETS[i]}
    if [[ "$name" == "$PRESET_CHOICE" ]]; then mark="(*)"; else mark="( )"; fi
    if ((i == TUI_SEL)); then style="page,accent,b"; else style="fg"; fi
    [[ "$name" == off ]] && name="none, plain Ayu"
    tui_put "$r" "$TUI_C0" 26 "$style" "$(printf '%s %-22s' "$mark" "$name")"
    r=$((r + 1))
  done
  name=${TUI_PRESETS[TUI_SEL]}
  TUI_ROW=$((TUI_R0 + 2)) TUI_COL=$((TUI_C0 + 30)) TUI_TW=$((TUI_CW - 30))
  tui_text "bright,,b" "$name"
  tui_text fg "${TUI_PRESET_DESC[$name]}"
  tui_gap
  tui_text muted "The colors come from the wallpaper, so Ghostty, kitty, GTK, KDE, Luciole and Firefox follow it."
  TUI_COL="" TUI_TW=""
  tui_footer "" "$G_UP$G_DOWN|move" "Space|choose" "Enter|continue" "Backspace|back" "Esc|quit"
}

# tui_plan: the review's numbers and lists, from the current choices.
tui_plan() {
  tui_sync
  mapfile -t TUI_PKGS < <(main_dnf_packages)
  mapfile -t TUI_FLATPAKS < <(chosen_by_source flatpak)
  mapfile -t TUI_REPOS < <(chosen_by_source repo)
  mapfile -t TUI_REMOVE < <(rpm -q --qf '%{NAME}\n' "${REPLACED_PACKAGES[@]}" 2>/dev/null | grep -v ' ' |
    grep -vxF -f <(printf '%s\n' "${TUI_PKGS[@]}") || true)
}

# tui_default_label ROLE -> the default app's name for ROLE, or "none".
tui_default_label() {
  local id=${TUI_DEFAULT[$1]:-}
  if [[ -n "$id" ]]; then echo "${CAT_LABEL[$id]}"; else echo none; fi
}

tui_screen_review() {
  local bw=$(((TUI_CW - 4) / 3)) top=$((TUI_R0 + 2)) bh col role repos
  tui_frame_begin
  tui_topbar "$(tui_step "$TUI_PAGE")"
  tui_wizard_sidebar "$TUI_PAGE"
  tui_put "$TUI_R0" "$TUI_C0" 30 "bright,,b" "Ready to install"
  tui_put "$TUI_R0" $((TUI_C0 + TUI_CW - 23)) 23 muted "nothing has changed yet"
  bh=$((TUI_R1 - top - 3))
  ((bh > 13)) && bh=13
  col=$TUI_C0
  tui_box "$top" "$col" "$bw" "$bh" "green,,b" "+ Adds"
  TUI_ROW=$((top + 1)) TUI_COL=$((col + 2)) TUI_TW=$((bw - 4)) TUI_RLIMIT=$((top + bh - 2))
  tui_text fg "${#TUI_PKGS[@]} packages"
  tui_text fg "${#DNF_PLASMA[@]} for Plasma"
  tui_text fg "${#TUI_FLATPAKS[@]} Flatpak apps"
  repos="RPM Fusion, Terra, Flathub"
  for role in "${TUI_REPOS[@]}"; do repos+=", $(tui_repo_label "$role")"; done
  tui_text muted "repos"
  tui_text fg "$repos"
  col=$((col + bw + 2))
  tui_box "$top" "$col" "$bw" "$bh" "accent,,b" "~ Sets up"
  TUI_ROW=$((top + 1)) TUI_COL=$((col + 2))
  for role in "${ROLES[@]}"; do tui_text fg "$role: $(tui_default_label "$role")"; done
  if [[ "$PRESET_CHOICE" == off ]]; then tui_text fg "look: plain Ayu"; else tui_text fg "look: $PRESET_CHOICE"; fi
  tui_text fg "login: Umbriel"
  if [[ -n "$TUI_MIGRATE" ]]; then tui_text muted "fedora-hyprland moved over"; fi
  col=$((col + bw + 2))
  tui_box "$top" "$col" "$bw" "$bh" "red,,b" "- Removes"
  TUI_ROW=$((top + 1)) TUI_COL=$((col + 2))
  if ((${#TUI_REMOVE[@]})); then
    tui_text fg "${#TUI_REMOVE[@]} packages"
    if [[ -n "$TUI_MIGRATE" ]]; then tui_text fg "the Hyprland COPR"; fi
    tui_text muted "$(printf '%s, ' "${TUI_REMOVE[@]}" | sed 's/, $//')"
  else
    tui_text muted "nothing"
  fi
  TUI_COL="" TUI_TW="" TUI_RLIMIT="" TUI_ROW=$((top + bh))
  tui_text muted "Apps you untick stay installed. Safe to stop: run it again and finished steps are skipped."
  tui_buttons "$TUI_R1" "$TUI_BTN" "Install now" "Show every package" "Back"
  tui_footer "your password is asked once" "Tab|next button" "Enter|press" "Backspace|back" "Esc|quit"
}

tui_screen_pager() {
  local r i rows=$((TUI_R1 - TUI_R0))
  tui_frame_begin
  tui_topbar "$(tui_step "$TUI_PAGE")"
  tui_wizard_sidebar "$TUI_PAGE"
  tui_put "$TUI_R0" "$TUI_C0" "$TUI_CW" "bright,,b" "Every package ($((TUI_OFF + 1))-$((TUI_OFF + rows < ${#TUI_PAGER[@]} ? TUI_OFF + rows : ${#TUI_PAGER[@]})) of ${#TUI_PAGER[@]})"
  r=$((TUI_R0 + 1))
  for ((i = TUI_OFF; i < ${#TUI_PAGER[@]} && r <= TUI_R1; i++)); do
    if [[ "${TUI_PAGER[i]}" == "# "* ]]; then
      tui_put "$r" "$TUI_C0" "$TUI_CW" "accent,,b" "${TUI_PAGER[i]#\# }"
    else
      tui_put "$r" $((TUI_C0 + 2)) $((TUI_CW - 2)) fg "${TUI_PAGER[i]}"
    fi
    r=$((r + 1))
  done
  tui_footer "" "$G_UP$G_DOWN|scroll" "PgUp PgDn|page" "Esc|back"
}

# tui_pager_lines: the review's package list, by menu.
tui_pager_lines() {
  local menu id
  TUI_PAGER=("# Base" "${DNF_DESKTOP[@]}" "${DNF_APPS[@]}" "${DNF_STORAGE[@]}" "${DNF_CLI[@]}" "${DNF_SYSTEM[@]}")
  for menu in "${CATEGORIES[@]}"; do
    TUI_PAGER+=("# ${menu#*|}")
    for id in $(catalog_ids "${menu%%|*}"); do
      if [[ -n "${TUI_ON[$id]:-}" ]]; then TUI_PAGER+=("${CAT_LABEL[$id]}: ${CAT_PACKAGES[$id]}"); fi
    done
  done
  TUI_PAGER+=("# KDE Plasma fallback" "${DNF_PLASMA[@]}")
  if ((${#TUI_REMOVE[@]})); then TUI_PAGER+=("# Removed" "${TUI_REMOVE[@]}"); fi
}

# Install: TUI_STATE[i] per STEPS entry: todo run done skip fail.
# tui_install_sidebar: the install steps with their state; sets TUI_DONE_STEPS.
tui_install_sidebar() {
  local i status style mark
  local -a lines=()
  TUI_DONE_STEPS=0
  for i in "${!STEPS[@]}"; do
    status=${TUI_STATE[i]}
    case "$status" in
      done) style=green mark=$G_DONE TUI_DONE_STEPS=$((TUI_DONE_STEPS + 1)) ;;
      run) style="accent,,b" mark=$G_RUN ;;
      fail) style="red,,b" mark=$G_FAIL ;;
      skip) style=muted mark=$G_SKIP TUI_DONE_STEPS=$((TUI_DONE_STEPS + 1)) ;;
      *) style=muted mark=$G_TODO ;;
    esac
    lines+=("$style|$mark ${STEPS[i]%%|*}")
  done
  tui_sidebar "${lines[@]}"
}

tui_screen_install() {
  local i title line r lines=() logh n=0 total=0 rest
  tui_frame_begin
  tui_topbar "$(tui_step $((${#TUI_WIZARD[@]} - 2))) $G_DOT $(printf '%02d:%02d' $((SECONDS / 60)) $((SECONDS % 60)))"
  tui_install_sidebar
  title=${STEPS[TUI_STEP]%%|*}
  # The step's own counter when its output has one (dnf's "[ 98/157]"), else the step count.
  line=$(tail -c +"$((TUI_LOG_START + 1))" "$LOG_FILE" 2>/dev/null | grep -oE '\[ *[0-9]+/[0-9]+\]' | tail -1 | tr -d '[] ' || true)
  if [[ -n "$line" ]]; then n=${line%/*} total=${line#*/}; fi
  tui_put "$TUI_R0" "$TUI_C0" "$TUI_CW" "bright,,b" "$title"
  if ((total > 0)); then
    rest="$n / $total"
    tui_put "$TUI_R0" $((TUI_C0 + TUI_CW - ${#rest})) "${#rest}" fg "$rest"
    tui_bar $((TUI_R0 + 1)) "$TUI_C0" "$TUI_CW" "$n" "$total"
  else
    tui_put $((TUI_R0 + 1)) "$TUI_C0" "$TUI_CW" muted "working$(tui_repeat . $((SECONDS % 4)))"
  fi
  rest="$TUI_DONE_STEPS of ${#STEPS[@]} steps"
  tui_put $((TUI_R0 + 3)) "$TUI_C0" 20 fg "Overall"
  tui_put $((TUI_R0 + 3)) $((TUI_C0 + TUI_CW - ${#rest})) "${#rest}" fg "$rest"
  tui_bar $((TUI_R0 + 4)) "$TUI_C0" "$TUI_CW" "$TUI_DONE_STEPS" "${#STEPS[@]}"
  # The log's last lines, in a box.
  r=$((TUI_R0 + 6))
  logh=$((TUI_R1 - r - 1))
  tui_box "$r" "$TUI_C0" "$TUI_CW" "$logh" muted "log"
  mapfile -t lines < <(tail -n $((logh - 2)) "$LOG_FILE" 2>/dev/null | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/.*\r//' -e 's/\t/  /g')
  for ((i = 0; i < ${#lines[@]}; i++)); do
    tui_put $((r + 1 + i)) $((TUI_C0 + 2)) $((TUI_CW - 4)) muted "${lines[i]}"
  done
  tui_put "$TUI_R1" "$TUI_C0" "$TUI_CW" muted "full log: ${LOG_FILE/#$HOME/\~}"
  tui_footer "safe to stop: run it again and finished steps are skipped" "Ctrl+C|stop"
}

tui_screen_done() {
  local ok=$1
  tui_frame_begin
  tui_topbar "$(tui_step $((${#TUI_WIZARD[@]} - 1))) $G_DOT $(printf '%02d:%02d' $((SECONDS / 60)) $((SECONDS % 60)))"
  TUI_ROW=$TUI_R0
  if [[ "$ok" == yes ]]; then
    tui_wizard_sidebar $((${#TUI_WIZARD[@]} - 1))
    tui_text "green,,b" "$G_DONE Installed"
    if [[ -n "${TUI_ON[fingerprint]:-}" ]]; then
      tui_text fg "When this window closes, put your finger on the reader to enroll it. Then reboot, and the login screen starts Umbriel."
    else
      tui_text fg "Reboot, and the login screen starts Umbriel."
    fi
    tui_gap
    tui_text "bright,,b" "update"
    tui_text muted "everything: packages, Flatpaks, firmware and these defaults"
    tui_text "bright,,b" "noctalia-preset"
    tui_text muted "switch the look"
    tui_text "bright,,b" "Plasma"
    tui_text muted "on the login screen, if Umbriel or a game misbehaves"
    tui_buttons "$TUI_R1" "$TUI_BTN" "Reboot now" "Exit"
  else
    tui_install_sidebar
    tui_text "red,,b" "$G_FAIL Stopped at: ${STEPS[TUI_STEP]%%|*}"
    tui_text fg "Fix the problem, then run install.sh again: finished steps are skipped."
    tui_gap
    local lines=() i
    mapfile -t lines < <(tail -n $((TUI_R1 - TUI_ROW - 2)) "$LOG_FILE" 2>/dev/null | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/.*\r//')
    for i in "${lines[@]}"; do tui_put "$TUI_ROW" "$TUI_C0" "$TUI_CW" muted "$i"; TUI_ROW=$((TUI_ROW + 1)); done
    tui_buttons "$TUI_R1" 0 "Exit"
  fi
  tui_footer "${LOG_FILE/#$HOME/\~}" "Tab|next button" "Enter|press"
}

# --- The controller.

# tui_draw SCREEN [ARGS]: one frame, or the "too small" notice.
tui_draw() {
  tui_size
  if ((TUI_W < 80 || TUI_H < 24)); then tui_screen_small; else "tui_screen_$1" "${@:2}"; fi
  tui_flush
}

# tui_screen_page: the current wizard page.
tui_screen_page() {
  case "${TUI_PAGES[TUI_PAGE]}" in
    welcome) tui_screen_welcome ;;
    menu:* | extras) tui_screen_list ;;
    look) tui_screen_look ;;
    review) tui_screen_review ;;
  esac
}

# tui_goto INDEX: opens a wizard page with its cursor reset.
tui_goto() {
  local i
  TUI_PAGE=$1 TUI_SEL=0 TUI_TOP=0 TUI_BTN=0
  case "${TUI_PAGES[TUI_PAGE]}" in
    look)
      tui_load_presets
      for i in "${!TUI_PRESETS[@]}"; do [[ "${TUI_PRESETS[i]}" == "$PRESET_CHOICE" ]] && TUI_SEL=$i; done
      ;;
    review) tui_plan ;;
  esac
}

# tui_list_key: a key on a menu or the extras page.
tui_list_key() {
  local id role n
  tui_page_ids
  n=${#TUI_IDS[@]} id=${TUI_IDS[TUI_SEL]}
  case "$KEY" in
    up) TUI_SEL=$((TUI_SEL > 0 ? TUI_SEL - 1 : 0)) ;;
    down | tab) TUI_SEL=$((TUI_SEL < n - 1 ? TUI_SEL + 1 : TUI_SEL)) ;;
    home) TUI_SEL=0 ;;
    end) TUI_SEL=$((n - 1)) ;;
    space)
      if [[ -z "${TUI_OFF_WHY[$id]:-}" ]]; then
        if [[ -n "${TUI_ON[$id]:-}" ]]; then TUI_ON[$id]=""; else TUI_ON[$id]=1; fi
        tui_sync
      fi
      ;;
    d)
      role=${CAT_ROLE[$id]:-}
      if [[ -n "$role" ]]; then TUI_ON[$id]=1 TUI_DEFAULT[$role]=$id; tui_sync; fi
      ;;
    enter | right) tui_goto $((TUI_PAGE + 1)) ;;
    back | left) tui_goto $((TUI_PAGE - 1)) ;;
  esac
}

# tui_wizard: the choices, page by page. Returns 0 on "Install now", 1 on quit.
tui_wizard() {
  local pager=""
  tui_goto 0
  while true; do
    if [[ -n "$pager" ]]; then tui_draw pager; else tui_draw page; fi
    tui_read_key 1
    [[ -z "$KEY" ]] && continue
    if [[ -n "$pager" ]]; then
      local page=$((TUI_R1 - TUI_R0)) max=$((${#TUI_PAGER[@]} - (TUI_R1 - TUI_R0)))
      ((max < 0)) && max=0
      case "$KEY" in
        up) TUI_OFF=$((TUI_OFF > 0 ? TUI_OFF - 1 : 0)) ;;
        down) TUI_OFF=$((TUI_OFF < max ? TUI_OFF + 1 : max)) ;;
        pgup) TUI_OFF=$((TUI_OFF > page ? TUI_OFF - page : 0)) ;;
        pgdn | space) TUI_OFF=$((TUI_OFF + page < max ? TUI_OFF + page : max)) ;;
        home) TUI_OFF=0 ;;
        end) TUI_OFF=$max ;;
        esc | back | left | enter | q) pager="" ;;
      esac
      continue
    fi
    if [[ "$KEY" == esc || "$KEY" == q ]]; then return 1; fi
    case "${TUI_PAGES[TUI_PAGE]}" in
      welcome)
        case "$KEY" in
          tab | right | left) TUI_BTN=$(((TUI_BTN + 1) % 2)) ;;
          enter) if ((TUI_BTN == 1)); then return 1; fi; tui_goto 1 ;;
        esac
        ;;
      menu:* | extras) tui_list_key ;;
      look)
        case "$KEY" in
          up) TUI_SEL=$((TUI_SEL > 0 ? TUI_SEL - 1 : 0)) ;;
          down | tab) TUI_SEL=$((TUI_SEL < ${#TUI_PRESETS[@]} - 1 ? TUI_SEL + 1 : TUI_SEL)) ;;
          space) PRESET_CHOICE=${TUI_PRESETS[TUI_SEL]} ;;
          enter | right) PRESET_CHOICE=${TUI_PRESETS[TUI_SEL]}; tui_goto $((TUI_PAGE + 1)) ;;
          back | left) tui_goto $((TUI_PAGE - 1)) ;;
        esac
        ;;
      review)
        case "$KEY" in
          tab | right) TUI_BTN=$(((TUI_BTN + 1) % 3)) ;;
          left) TUI_BTN=$(((TUI_BTN + 2) % 3)) ;;
          back) tui_goto $((TUI_PAGE - 1)) ;;
          enter)
            case "$TUI_BTN" in
              0) return 0 ;;
              1) tui_pager_lines; TUI_OFF=0; pager=1 ;;
              2) tui_goto $((TUI_PAGE - 1)) ;;
            esac
            ;;
        esac
        ;;
    esac
  done
}

# tui_answers: the wizard's choices as the variables the install steps read.
tui_answers() {
  local key
  tui_sync
  export ASSUME=yes DEFER_FINGERPRINT=1 APPLY_DEFAULTS=1 PRESET_CHOICE SOFTWARE_ITEMS
  export DEFAULT_TERMINAL DEFAULT_BROWSER DEFAULT_FILES DEFAULT_EDITOR
  for key in home-snapshots grub-btrfs; do
    if [[ "${TUI_OFF_WHY[$key]:-}" == "already on" ]]; then continue; fi
    if [[ -n "${TUI_ON[$key]:-}" ]]; then export "ANSWER_${key//-/_}=yes"; else export "ANSWER_${key//-/_}=no"; fi
  done
  # Without lspci (a fresh Minimal Install) the card is only checked during the install: leave it to setup_nvidia.
  if [[ "${TUI_OFF_WHY[nvidia]:-}" == "checked later" ]]; then return 0; fi
  if [[ -n "${TUI_ON[nvidia]:-}" ]]; then export NVIDIA=yes; else export NVIDIA=no; fi
}

# tui_install: runs STEPS one by one in the background, drawing progress. Returns 1 when a step fails.
tui_install() {
  local i pid fn
  TUI_STATE=()
  for i in "${!STEPS[@]}"; do TUI_STATE[i]=todo; done
  mkdir -p "$(dirname "$LOG_FILE")"
  : >>"$LOG_FILE"
  SECONDS=0
  for i in "${!STEPS[@]}"; do
    fn=${STEPS[i]#*|}
    if [[ "$fn" == setup_nvidia && "${NVIDIA:-}" == no ]]; then TUI_STATE[i]=skip; continue; fi
    TUI_STEP=$i TUI_STATE[i]=run
    TUI_LOG_START=$(stat -c %s "$LOG_FILE")
    printf '\n==> %s\n' "${STEPS[i]%%|*}" >>"$LOG_FILE"
    ("$fn") >>"$LOG_FILE" 2>&1 </dev/null &
    pid=$!
    trap 'kill "$pid" 2>/dev/null; tui_stop; echo "Stopped. Run install.sh again to continue; finished steps are skipped."; exit 130' INT TERM
    while kill -0 "$pid" 2>/dev/null; do
      tui_draw install
      tui_read_key 0.3
    done
    if ! wait "$pid"; then TUI_STATE[i]=fail; return 1; fi
    TUI_STATE[i]="done"
  done
  return 0
}

# tui_finish OK: the last screen; reboots when asked.
tui_finish() {
  local ok=$1 reboot=""
  TUI_BTN=0
  while true; do
    tui_draw "done" "$ok"
    tui_read_key 1
    case "$KEY" in
      tab | right | left) [[ "$ok" == yes ]] && TUI_BTN=$(((TUI_BTN + 1) % 2)) ;;
      enter) if [[ "$ok" == yes && "$TUI_BTN" == 0 ]]; then reboot=1; fi; break ;;
      esc | q) break ;;
    esac
  done
  tui_stop
  if [[ "$ok" != yes ]]; then
    warn "Stopped at ${STEPS[TUI_STEP]%%|*}. Full log: $LOG_FILE"
    return 1
  fi
  if [[ -n "${TUI_ON[fingerprint]:-}" ]]; then ANSWER_fingerprint=yes enroll_fingerprint; fi
  if [[ -n "$reboot" ]]; then systemctl reboot; fi
  log "Done. Reboot to start Umbriel: systemctl reboot"
}

tui_main() {
  preflight_checks
  tui_pages
  tui_colors "$(tui_color_mode "${TERM:-}" "${COLORTERM:-}")"
  tui_glyphs "${TERM:-}"
  tui_detect
  tui_defaults
  tui_start
  if ! tui_wizard; then
    tui_stop
    echo "Nothing was changed."
    return 0
  fi
  tui_plan
  tui_answers
  # The password prompt happens on the normal screen, once; then sudo stays fresh for the whole run.
  tui_stop
  echo "The installer needs your password once, for dnf and the system settings."
  sudo_session
  save_choices
  tui_start
  if tui_install; then tui_finish yes; else tui_finish no; fi
}

tui_pages
