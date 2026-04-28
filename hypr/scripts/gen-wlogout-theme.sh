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
read C1_R C1_G C1_B <<< "$(hex_to_rgb "$color1")"
read C2_R C2_G C2_B <<< "$(hex_to_rgb "$color2")"
read C3_R C3_G C3_B <<< "$(hex_to_rgb "$color3")"
read C4_R C4_G C4_B <<< "$(hex_to_rgb "$color4")"
read C5_R C5_G C5_B <<< "$(hex_to_rgb "$color5")"
read C6_R C6_G C6_B <<< "$(hex_to_rgb "$color6")"

sed \
  -e "s|@BG@|$background|g" \
  -e "s|@FG@|$foreground|g" \
  -e "s|@COLOR0@|$color0|g" \
  -e "s|@COLOR1@|$color1|g" \
  -e "s|@COLOR2@|$color2|g" \
  -e "s|@COLOR3@|$color3|g" \
  -e "s|@COLOR4@|$color4|g" \
  -e "s|@COLOR5@|$color5|g" \
  -e "s|@COLOR6@|$color6|g" \
  -e "s|@BG_R@|$BG_R|g" \
  -e "s|@BG_G@|$BG_G|g" \
  -e "s|@BG_B@|$BG_B|g" \
  -e "s|@C0_R@|$C0_R|g" \
  -e "s|@C0_G@|$C0_G|g" \
  -e "s|@C0_B@|$C0_B|g" \
  -e "s|@C1_R@|$C1_R|g" \
  -e "s|@C1_G@|$C1_G|g" \
  -e "s|@C1_B@|$C1_B|g" \
  -e "s|@C2_R@|$C2_R|g" \
  -e "s|@C2_G@|$C2_G|g" \
  -e "s|@C2_B@|$C2_B|g" \
  -e "s|@C3_R@|$C3_R|g" \
  -e "s|@C3_G@|$C3_G|g" \
  -e "s|@C3_B@|$C3_B|g" \
  -e "s|@C4_R@|$C4_R|g" \
  -e "s|@C4_G@|$C4_G|g" \
  -e "s|@C4_B@|$C4_B|g" \
  -e "s|@C5_R@|$C5_R|g" \
  -e "s|@C5_G@|$C5_G|g" \
  -e "s|@C5_B@|$C5_B|g" \
  -e "s|@C6_R@|$C6_R|g" \
  -e "s|@C6_G@|$C6_G|g" \
  -e "s|@C6_B@|$C6_B|g" \
  "$TEMPLATE" > "$OUTPUT"

echo "Generated $OUTPUT"