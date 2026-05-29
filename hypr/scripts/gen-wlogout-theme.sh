#!/usr/bin/env bash

set -e

WAL="$HOME/.cache/wal/colors.sh"
TEMPLATE="$HOME/.config/wlogout/style.css.in"
OUTPUT="$HOME/.config/wlogout/style.css"

[[ -f "$WAL" ]] || { echo "Missing $WAL"; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "Missing $TEMPLATE"; exit 1; }

source "$WAL"

hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d %d %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

read BG_R BG_G BG_B <<< "$(hex_to_rgb "$background")"
read C0_R C0_G C0_B <<< "$(hex_to_rgb "$color0")"
read C4_R C4_G C4_B <<< "$(hex_to_rgb "$color4")"
read C5_R C5_G C5_B <<< "$(hex_to_rgb "$color5")"

sed \
  -e "s|@BG@|$background|g" \
  -e "s|@FG@|$foreground|g" \
  -e "s|@COLOR4@|$color4|g" \
  -e "s|@C0_R@|$C0_R|g" \
  -e "s|@C0_G@|$C0_G|g" \
  -e "s|@C0_B@|$C0_B|g" \
  -e "s|@C4_R@|$C4_R|g" \
  -e "s|@C4_G@|$C4_G|g" \
  -e "s|@C4_B@|$C4_B|g" \
  -e "s|@C5_R@|$C5_R|g" \
  -e "s|@C5_G@|$C5_G|g" \
  -e "s|@C5_B@|$C5_B|g" \
  "$TEMPLATE" > "$OUTPUT"

echo "wlogout theme generated"