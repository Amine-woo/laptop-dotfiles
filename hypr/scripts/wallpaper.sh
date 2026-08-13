#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper"
THUMB_CACHE_DIR="$HOME/.cache/wallpaper-selector"

THUMB_WIDTH=700
THUMB_HEIGHT=394
WOFI_IMAGE_SIZE=320

mkdir -p "$HOME/.cache"
mkdir -p "$THUMB_CACHE_DIR"
mkdir -p "$HOME/.config/hypr/hyprland"
mkdir -p "$HOME/.config/orbit"
mkdir -p "$HOME/.config/swayosd"

load_pywal() {
    set +u
    source "$HOME/.cache/wal/colors.sh"
    set -u
}

write_hypr_theme() {
    load_pywal

    local fg bg c1 c5 c8

    fg="${foreground#\#}"
    bg="${background#\#}"
    c1="${color1#\#}"
    c5="${color5#\#}"
    c8="${color8#\#}"

    cat > "$HOME/.config/hypr/hyprland/theme.conf" <<EOF2
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
EOF2
}

write_orbit_theme() {
    load_pywal

    cat > "$HOME/.config/orbit/theme.toml" <<EOF2
accent_primary = "$color5"
accent_secondary = "$color4"
background = "$background"
foreground = "$foreground"
EOF2
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

        printf 'img:%s\x00info:%s\x1f%s\n' \
            "$thumb" \
            "$(basename "$img")" \
            "$img"
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

    find "$WALLPAPER_DIR" \
        -maxdepth 1 \
        -type f \
        -name "${original_name}.*" \
        | head -n 1
}

reload_swayosd() {
    "$HOME/.config/hypr/scripts/swayosd-pywal.sh" || true

    pkill -x swayosd-server 2>/dev/null || true

    for _ in {1..20}; do
        if ! pgrep -x swayosd-server >/dev/null; then
            break
        fi
        sleep 0.05
    done

    sleep 0.2

    setsid -f bash -c \
        'swayosd-server -s "$HOME/.config/swayosd/style.css" >/tmp/swayosd.log 2>&1'
}

reload_wlogout_theme() {
    local script="$HOME/.config/hypr/scripts/gen-wlogout-theme.sh"

    if [[ -f "$script" ]]; then
        chmod +x "$script"
        "$script" || true
    fi
}

reload_waybar() {
    local script="$HOME/.config/hypr/scripts/restart-waybar.sh"

    if [[ -x "$script" ]]; then
        "$script" || true
    else
        pkill -x waybar 2>/dev/null || true
        sleep 0.3
        setsid -f bash -c 'waybar >/tmp/waybar.log 2>&1'
    fi
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

    "$HOME/.config/hypr/scripts/gen-hyprlock-pywal.sh" || true

    hyprctl reload >/dev/null 2>&1 || true

    reload_swayosd

    orbit reload-theme >/dev/null 2>&1 || true

    reload_wlogout_theme

    reload_waybar
}

main() {
    local img

    if [[ "${1:-}" == "--random" ]]; then
        img="$(pick_random)"
    else
        img="$(pick_with_wofi)"
    fi

    [[ -n "$img" ]] || exit 0

    apply_wallpaper "$img"
}

main "$@"
