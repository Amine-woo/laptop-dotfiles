#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_DIR="/home/amine/Pictures/Wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper"
THUMB_CACHE_DIR="$HOME/.cache/wallpaper-selector"

THUMB_WIDTH=700
THUMB_HEIGHT=394
WOFI_IMAGE_SIZE=320

mkdir -p "$HOME/.cache"
mkdir -p "$THUMB_CACHE_DIR"
mkdir -p "$HOME/.config/hypr/hyprland"
mkdir -p "$HOME/.config/orbit"

kitty_color() {
    awk -v key="$1" '$1 == key { sub(/^#/, "", $2); print $2; exit }' "$HOME/.cache/wal/colors-kitty.conf" 2>/dev/null
}

write_hypr_theme() {
    local fg bg c1 c5 c8

    fg="$(kitty_color foreground || echo "ffffff")"
    bg="$(kitty_color background || echo "111111")"
    c1="$(kitty_color color1 || echo "ff5555")"
    c5="$(kitty_color color5 || echo "cba6f7")"
    c8="$(kitty_color color8 || echo "888888")"

    cat > "$HOME/.config/hypr/hyprland/theme.conf" <<EOF
general {
    border_size = 0
    gaps_in = 10
    gaps_out = 20
    gaps_workspaces = 0
    col.active_border = rgb($c5) 45deg
    col.inactive_border = rgba(00000000)
    layout = dwindle
    resize_on_border = true
    extend_border_grab_area = 15
    hover_icon_on_border = true
}

decoration {
    rounding = 10
    rounding_power = 2.0
    fullscreen_opacity = 1.0

    blur {
        enabled = true
        size = 8
        passes = 2
        new_optimizations = true
        ignore_opacity = false
        noise = 0.02
        contrast = 0.85
        brightness = 0.65
    }

    shadow {
        enabled = true
        range = 10
        render_power = 3
        ignore_window = true
        color = 0xcc000000
        offset = 0 0
        scale = 1.0
    }

    dim_strength = 0.3
    dim_around = 0.6
}

animations {
    enabled = yes
    bezier = smoothIn, 0.25, 1, 0.5, 1
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = easeInOutCubic, 0.65, 0.05, 0.36, 1
    animation = workspaces, 1, 2, easeInOutCubic, slidevert
    animation = workspacesIn, 1, 2, easeInOutCubic, slidevert
    animation = workspacesOut, 1, 2, easeInOutCubic, slidevert
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    mfact = 0.55
    new_status = master
}

group {
    col.border_active = rgb($c1)
    col.border_inactive = rgb($c8)

    groupbar {
        font_family = sans-serif
        font_size = 11
        gradients = true
        render_titles = true
        scrolling = true
        text_color = rgb($fg)
        col.active = rgb($c5)
        col.inactive = rgb($c8)
    }
}

misc {
    animate_mouse_windowdragging = true
    focus_on_activate = true
    background_color = rgb($bg)
    disable_hyprland_logo = false
    force_default_wallpaper = 1
}

cursor {
    inactive_timeout = 5
    no_warps = false
    hide_on_key_press = false
    hide_on_touch = true
}
EOF
}

write_orbit_theme() {
    local fg bg c4 c5

    fg="$(kitty_color foreground || echo "ffffff")"
    bg="$(kitty_color background || echo "111111")"
    c4="$(kitty_color color4 || echo "89b4fa")"
    c5="$(kitty_color color5 || echo "cba6f7")"

    cat > "$HOME/.config/orbit/theme.toml" <<EOF
accent_primary = "#$c5"
accent_secondary = "#$c4"
background = "#$bg"
foreground = "#$fg"
EOF

    orbit reload-theme >/dev/null 2>&1 || true
}

list_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.webp" \
    \) | sort
}

pick_random() {
    mapfile -t WALLS < <(list_wallpapers)
    [[ ${#WALLS[@]} -eq 0 ]] && exit 1
    printf '%s\n' "${WALLS[RANDOM % ${#WALLS[@]}]}"
}

generate_menu() {
    while IFS= read -r img; do
        local thumb
        thumb="$THUMB_CACHE_DIR/$(basename "${img%.*}").png"

        if [[ ! -f "$thumb" || "$img" -nt "$thumb" ]]; then
            magick "$img" \
                -thumbnail "${THUMB_WIDTH}x${THUMB_HEIGHT}^" \
                -gravity center \
                -extent "${THUMB_WIDTH}x${THUMB_HEIGHT}" \
                "$thumb"
        fi

        printf 'img:%s\x00info:%s\x1f%s\n' "$thumb" "$(basename "$img")" "$img"
    done < <(list_wallpapers)
}

pick_with_wofi() {
    local selected
    selected="$(
        generate_menu | wofi --show dmenu \
            --allow-images \
            --cache-file /dev/null \
            --define "image_size=${WOFI_IMAGE_SIZE}" \
            --width 400 \
            --height 720 \
            --insensitive \
            --sort-order=default \
            --prompt "WofiPaper Selector by : AmineWoo"
    )"

    [[ -z "$selected" ]] && exit 0

    local thumb_path="${selected#img:}"
    local original_name
    original_name="$(basename "${thumb_path%.*}")"

    find "$WALLPAPER_DIR" -maxdepth 1 -type f -name "${original_name}.*" | head -n 1
}



apply_wallpaper() {
    local img="$1"
    [[ -f "$img" ]] || exit 1

    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        nohup awww-daemon >/dev/null 2>&1 &
        sleep 1
    fi

    awww img "$img" \
        --transition-type wipe \
        --transition-duration 1 \
        --transition-fps 60 \
        --transition-pos 0.5,0.5

    printf '%s\n' "$img" > "$STATE_FILE"

wal -i "$img"

write_hypr_theme
write_orbit_theme

~/.config/hypr/scripts/swayosd-pywal.sh

pkill swayosd-server || true
swayosd-server -s ~/.config/swayosd/style.css &

hyprctl reload

chmod +x ~/.config/hypr/scripts/gen-wlogout-theme.sh
~/.config/hypr/scripts/gen-wlogout-theme.sh

pkill -x waybar || true
while pgrep -x waybar >/dev/null; do sleep 0.1; done
waybar >/dev/null 2>&1 &2
}

main() {
    local img

    if [[ "${1:-}" == "--random" ]]; then
        img="$(pick_random)"
    else
        img="$(pick_with_wofi)"
    fi

    apply_wallpaper "$img"
}

main "$@"