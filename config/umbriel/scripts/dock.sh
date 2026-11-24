#!/usr/bin/env bash
# Started once by Umbriel (autostart):
#  - the laptop panel is on only while no external monitor is connected
#  - the dock layout: HP E27q G5 portrait on the left, HP X27i on the right at its highest refresh rate, top-aligned.
#    Umbriel matches monitors by "make model serial", so the first time each HP monitor shows up its exact
#    name is written to ~/.config/umbriel/monitors.toml (Umbriel reloads it on its own).
set -u
MONITORS="${XDG_CONFIG_HOME:-$HOME/.config}/umbriel/monitors.toml"
unwrap='if type == "object" then .ok else . end'

write_monitors() {
  local outs="$1" portrait main tmp
  portrait=$(jq -r 'map(select(.model | test("E27q G5"))) | .[0].config_name // empty' <<<"$outs")
  main=$(jq -r 'map(select(.model | test("X27i"))) | .[0].config_name // empty' <<<"$outs")
  # Nothing new to add?
  [[ -z "$portrait" || -f "$MONITORS" && $(grep -cF "\"$portrait\"" "$MONITORS") -gt 0 ]] && portrait=""
  [[ -z "$main" || -f "$MONITORS" && $(grep -cF "\"$main\"" "$MONITORS") -gt 0 ]] && main=""
  [[ -z "$portrait" && -z "$main" ]] && return

  tmp=$(mktemp "$MONITORS.XXXXXX")
  if [[ -f "$MONITORS" ]]; then cat "$MONITORS" >"$tmp"; else
    echo "# Dock monitors, written by scripts/dock.sh. Edit freely; existing sections are kept." >"$tmp"
  fi
  if [[ -n "$portrait" ]]; then
    cat >>"$tmp" <<EOF

# HP E27q G5, portrait on the left (upside down? use "90")
[output."$portrait"]
position = [0, 0]
scale = 1
transform = "270"
workspaces = 5
workspace_axis = "horizontal"

# Tall screen: new windows split top/bottom instead of a master column.
[output."$portrait".layout]
mode = "dwindle"
EOF
  fi
  if [[ -n "$main" ]]; then
    local mode
    mode=$(jq -r --arg n "$main" 'map(select(.config_name == $n)) | .[0].modes
      | max_by([.width * .height, .refresh_mhz]) | "\(.width)x\(.height)@\((.refresh_mhz / 1000) | round)"' <<<"$outs")
    cat >>"$tmp" <<EOF

# HP X27i, main monitor on the right, highest refresh rate the dock allows
[output."$main"]
mode = "$mode"
position = [1440, 0]
scale = 1
workspaces = 5
workspace_axis = "horizontal"
focus_at_startup = true
EOF
  fi
  mv "$tmp" "$MONITORS"
}

panel() {
  local outs="$1" external
  external=$(jq '[.[] | select(.name | test("^(eDP|HEADLESS|NOOP)") | not)] | length' <<<"$outs")
  jq -r '.[] | select(.name | test("^eDP")) | "\(.name) \(.enabled)"' <<<"$outs" | while read -r name enabled; do
    if (( external > 0 )) && [[ "$enabled" == true ]]; then umbriel msg output-disable "$name" >/dev/null
    elif (( external == 0 )) && [[ "$enabled" == false ]]; then umbriel msg output-enable "$name" >/dev/null
    fi
  done
}

umbriel subscribe outputs | while read -r line; do
  outs=$(jq -c ".data // empty" <<<"$line") || continue
  [[ -z "$outs" ]] && continue
  write_monitors "$outs"
  panel "$outs"
done
