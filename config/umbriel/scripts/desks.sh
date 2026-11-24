#!/usr/bin/env bash
# Five linked desks. Each monitor has its own workspaces 1-5 in Umbriel,
# so desk N is workspace N on every monitor.
#   desks.sh focus N     show desk N on every monitor (the focused monitor keeps the focus)
#   desks.sh step -1|1   previous/next desk, stopping at 1 and 5 like Windows
#   desks.sh carry -1|1  the same, taking the focused window along
set -u
COUNT=5

unwrap='if type == "object" then .ok else . end'

# Enabled outputs, the focused one last so it keeps the focus.
outputs() {
  umbriel outputs --json | jq -r "$unwrap | map(select(.enabled)) | sort_by(.focused) | .[].name"
}

current() {
  umbriel workspaces --json | jq -r "$unwrap | map(select(.focused)) | (.[0].index // 1)"
}

focus_desk() {
  local o
  for o in $(outputs); do umbriel msg workspace-switch "$1" --output "$o" >/dev/null; done
}

clamp() {
  local n=$(( $1 + $2 ))
  (( n < 1 )) && n=1
  (( n > COUNT )) && n=$COUNT
  echo "$n"
}

case "${1:-}" in
  focus) focus_desk "$2" ;;
  step) focus_desk "$(clamp "$(current)" "$2")" ;;
  carry)
    n=$(clamp "$(current)" "$2")
    umbriel msg window-move-to-workspace-silent "$n" >/dev/null
    focus_desk "$n"
    ;;
  *) echo "usage: $0 focus N | step -1|1 | carry -1|1" >&2; exit 2 ;;
esac
