# shellcheck shell=bash
# make_edid FILE MAKE PRODUCT NAME SERIAL WIDTH_CM: a minimal EDID (no timings) with a name and a serial string, enough
# for the monitor scanner. MAKE is the three-letter PNP id, PRODUCT the product code in hex.
make_edid() {
  local out=$1 make=$2 product=$((16#$3)) name=$4 serial=$5 width=$6 code hex="" i b
  code=$((($(printf '%d' "'${make:0:1}") - 64) << 10 | ($(printf '%d' "'${make:1:1}") - 64) << 5 | ($(printf '%d' "'${make:2:1}") - 64)))
  hexb() { printf '\\x%02x' "$1"; }
  hex+='\x00\xff\xff\xff\xff\xff\xff\x00'
  hex+=$(hexb $((code >> 8)))$(hexb $((code & 255)))$(hexb $((product & 255)))$(hexb $((product >> 8)))
  hex+='\x00\x00\x00\x00\x01\x1f\x01\x04\xa5'$(hexb "$width")'\x13\x78'
  for ((i = 24; i < 54; i++)); do hex+='\x00'; done
  descriptor() { # TYPE TEXT
    local t=$1 text=$2 k
    hex+='\x00\x00\x00'$(hexb "$t")'\x00'
    for ((k = 0; k < 13; k++)); do
      if ((k < ${#text})); then hex+=$(hexb "$(printf '%d' "'${text:k:1}")"); elif ((k == ${#text})); then hex+='\x0a'; else hex+='\x20'; fi
    done
  }
  descriptor 16 ""
  descriptor 252 "$name"
  if [[ -n "$serial" ]]; then descriptor 255 "$serial"; else descriptor 16 ""; fi
  descriptor 16 ""
  hex+='\x00\x00'
  printf '%b' "$hex" >"$out"
  b=$(wc -c <"$out")
  ((b == 128)) || echo "make_edid: $b bytes" >&2
}

# fake_monitor DRM CONNECTOR MODE MAKE PRODUCT NAME SERIAL WIDTH_CM: a connected monitor in a fake /sys/class/drm.
fake_monitor() {
  mkdir -p "$1/card1-$2"
  echo connected >"$1/card1-$2/status"
  echo "$3" >"$1/card1-$2/modes"
  make_edid "$1/card1-$2/edid" "$4" "$5" "$6" "$7" "$8"
}
