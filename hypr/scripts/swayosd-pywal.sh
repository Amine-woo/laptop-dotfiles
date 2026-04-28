#!/usr/bin/env bash

WAL="$HOME/.cache/wal/colors.sh"
OUTDIR="$HOME/.config/swayosd"
OUT="$OUTDIR/style.css"

mkdir -p "$OUTDIR"

# charge les variables pywal: $background $foreground $color0 ... $color15
source "$WAL"

cat > "$OUT" <<EOF
window#osd {
    padding: 12px;
    border-radius: 18px;
    border: 2px solid ${color4};
    background: alpha(${background}, 0.88);
}

#container {
    margin: 8px;
}

image,
label {
    color: ${foreground};
}

progressbar:disabled,
image:disabled {
    opacity: 0.5;
}

progressbar {
    min-height: 8px;
    border-radius: 999px;
    background: alpha(${color8}, 0.35);
    border: none;
}

progress {
    min-height: 8px;
    border-radius: 999px;
    background: ${color4};
    border: none;
}

trough {
    min-height: 8px;
    border-radius: 999px;
    background: alpha(${color8}, 0.35);
    border: none;
}

slider {
    min-height: 0px;
    min-width: 0px;
    opacity: 0;
    background: transparent;
    border: none;
    box-shadow: none;
}
EOF