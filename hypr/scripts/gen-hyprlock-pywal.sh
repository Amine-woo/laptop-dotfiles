#!/usr/bin/env bash
set -euo pipefail

WAL="$HOME/.cache/wal/colors.sh"
OUT="$HOME/.cache/wal/colors-hyprlock"

set +u
source "$WAL"
set -u

strip_hash() {
    printf '%s' "${1#\#}"
}

mkdir -p "$HOME/.cache/wal"

cat > "$OUT" <<EOF2
\$foreground = rgb($(strip_hash "$foreground"))
\$background = rgb($(strip_hash "$background"))

\$color0 = rgb($(strip_hash "$color0"))
\$color1 = rgb($(strip_hash "$color1"))
\$color2 = rgb($(strip_hash "$color2"))
\$color3 = rgb($(strip_hash "$color3"))
\$color4 = rgb($(strip_hash "$color4"))
\$color5 = rgb($(strip_hash "$color5"))
\$color6 = rgb($(strip_hash "$color6"))
\$color7 = rgb($(strip_hash "$color7"))
\$color8 = rgb($(strip_hash "$color8"))
\$color9 = rgb($(strip_hash "$color9"))
\$color10 = rgb($(strip_hash "$color10"))
\$color11 = rgb($(strip_hash "$color11"))
\$color12 = rgb($(strip_hash "$color12"))
\$color13 = rgb($(strip_hash "$color13"))
\$color14 = rgb($(strip_hash "$color14"))
\$color15 = rgb($(strip_hash "$color15"))
EOF2
