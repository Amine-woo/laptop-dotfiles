#!/usr/bin/env python3

import re
import subprocess
from pathlib import Path
from xml.sax.saxutils import escape

HOME = Path.home()
CACHE = HOME / ".cache"

SVG_FILE = CACHE / "hyprlock-pokemon.svg"
PNG_FILE = CACHE / "hyprlock-pokemon.png"


# ============================================================
# PIXEL SIZE
#
# One terminal character represents two vertical Pokemon pixels.
# Therefore:
#
# CELL WIDTH  = 10
# CELL HEIGHT = 20
#
# top/bottom half = 10x10 => actual square pixels.
# ============================================================

PX = 10
CELL_W = PX
CELL_H = PX * 2

PADDING = 2


# ============================================================
# COLORS
# ============================================================

ANSI16 = {
    30: "#000000",
    31: "#aa0000",
    32: "#00aa00",
    33: "#aa5500",
    34: "#0000aa",
    35: "#aa00aa",
    36: "#00aaaa",
    37: "#aaaaaa",

    90: "#555555",
    91: "#ff5555",
    92: "#55ff55",
    93: "#ffff55",
    94: "#5555ff",
    95: "#ff55ff",
    96: "#55ffff",
    97: "#ffffff",
}


ANSI_BASIC = [
    "#000000",
    "#800000",
    "#008000",
    "#808000",
    "#000080",
    "#800080",
    "#008080",
    "#c0c0c0",
    "#808080",
    "#ff0000",
    "#00ff00",
    "#ffff00",
    "#0000ff",
    "#ff00ff",
    "#00ffff",
    "#ffffff",
]


def color256(value):
    value = int(value)

    if value < 16:
        return ANSI_BASIC[value]

    if value <= 231:
        value -= 16

        r = value // 36
        g = (value % 36) // 6
        b = value % 6

        def channel(n):
            return 0 if n == 0 else 55 + (n * 40)

        return "#{:02x}{:02x}{:02x}".format(
            channel(r),
            channel(g),
            channel(b),
        )

    gray = 8 + ((value - 232) * 10)

    return "#{:02x}{:02x}{:02x}".format(
        gray,
        gray,
        gray,
    )


# ============================================================
# ANSI STATE
# ============================================================

def apply_sgr(params, fg, bg):
    if not params:
        return None, None

    values = []

    for part in params.split(";"):
        try:
            values.append(int(part or "0"))
        except ValueError:
            values.append(0)

    i = 0

    while i < len(values):
        code = values[i]

        if code == 0:
            fg = None
            bg = None

        elif code == 39:
            fg = None

        elif code == 49:
            bg = None

        elif code in ANSI16:
            fg = ANSI16[code]

        elif 40 <= code <= 47:
            fg_code = code - 10
            bg = ANSI16.get(fg_code)

        elif 100 <= code <= 107:
            fg_code = code - 10
            bg = ANSI16.get(fg_code)

        elif code in (38, 48):
            is_fg = code == 38

            if i + 1 < len(values):
                mode = values[i + 1]

                # 256 color
                if mode == 5 and i + 2 < len(values):
                    color = color256(values[i + 2])

                    if is_fg:
                        fg = color
                    else:
                        bg = color

                    i += 2

                # RGB
                elif mode == 2 and i + 4 < len(values):
                    r = values[i + 2]
                    g = values[i + 3]
                    b = values[i + 4]

                    color = "#{:02x}{:02x}{:02x}".format(
                        r, g, b
                    )

                    if is_fg:
                        fg = color
                    else:
                        bg = color

                    i += 4

        i += 1

    return fg, bg


# ============================================================
# PARSE POKEMON-COLORSCRIPTS OUTPUT
# ============================================================

SGR = re.compile(r"\x1b\[([0-9;]*)m")


def parse(text):
    rows = []

    fg = None
    bg = None

    x = 0
    y = 0

    pixels = []

    pos = 0

    def draw_character(char, x, y, fg, bg):

        # Completely empty terminal cell.
        if char == " ":
            if bg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W, CELL_H, bg)
                )
            return


        # FULL BLOCK
        if char == "█":
            if fg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W, CELL_H, fg)
                )
            elif bg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W, CELL_H, bg)
                )
            return


        # UPPER HALF BLOCK
        if char == "▀":
            if fg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W, PX, fg)
                )

            if bg:
                pixels.append(
                    (x * CELL_W, y * CELL_H + PX,
                     CELL_W, PX, bg)
                )

            return


        # LOWER HALF BLOCK
        if char == "▄":
            if bg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W, PX, bg)
                )

            if fg:
                pixels.append(
                    (x * CELL_W, y * CELL_H + PX,
                     CELL_W, PX, fg)
                )

            return


        # LEFT HALF BLOCK
        if char == "▌":
            if fg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W // 2, CELL_H, fg)
                )

            if bg:
                pixels.append(
                    (
                        x * CELL_W + CELL_W // 2,
                        y * CELL_H,
                        CELL_W // 2,
                        CELL_H,
                        bg,
                    )
                )

            return


        # RIGHT HALF BLOCK
        if char == "▐":
            if bg:
                pixels.append(
                    (x * CELL_W, y * CELL_H,
                     CELL_W // 2, CELL_H, bg)
                )

            if fg:
                pixels.append(
                    (
                        x * CELL_W + CELL_W // 2,
                        y * CELL_H,
                        CELL_W // 2,
                        CELL_H,
                        fg,
                    )
                )

            return


        # Other characters:
        # Pokemon-colorscripts normally doesn't need them for
        # the sprite, but preserve colored background.
        if bg:
            pixels.append(
                (x * CELL_W, y * CELL_H,
                 CELL_W, CELL_H, bg)
            )


    while pos < len(text):

        match = SGR.match(text, pos)

        if match:
            fg, bg = apply_sgr(
                match.group(1),
                fg,
                bg,
            )

            pos = match.end()
            continue


        char = text[pos]


        if char == "\n":
            y += 1
            x = 0

        elif char == "\r":
            x = 0

        else:
            draw_character(
                char,
                x,
                y,
                fg,
                bg,
            )

            x += 1


        pos += 1


    return pixels


# ============================================================
# CROP TO ACTUAL POKEMON
# ============================================================

def crop_pixels(pixels):
    if not pixels:
        return [], 100, 100

    min_x = min(p[0] for p in pixels)
    min_y = min(p[1] for p in pixels)

    max_x = max(p[0] + p[2] for p in pixels)
    max_y = max(p[1] + p[3] for p in pixels)

    result = []

    for x, y, w, h, color in pixels:
        result.append(
            (
                x - min_x + PADDING,
                y - min_y + PADDING,
                w,
                h,
                color,
            )
        )

    width = (
        max_x - min_x
        + PADDING * 2
    )

    height = (
        max_y - min_y
        + PADDING * 2
    )

    return result, width, height


# ============================================================
# SVG
# ============================================================

def build_svg(pixels, width, height):
    parts = [
        (
            f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{width}" height="{height}" '
            f'viewBox="0 0 {width} {height}" '
            f'shape-rendering="crispEdges">'
        )
    ]

    for x, y, w, h, color in pixels:
        parts.append(
            f'<rect x="{x}" y="{y}" '
            f'width="{w}" height="{h}" '
            f'fill="{escape(color)}"/>'
        )

    parts.append("</svg>")

    return "\n".join(parts)


# ============================================================
# MAIN
# ============================================================

def main():

    CACHE.mkdir(
        parents=True,
        exist_ok=True,
    )


    result = subprocess.run(
        [
            "pokemon-colorscripts",
            "-r",
            "--no-title",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        errors="replace",
        timeout=5,
    )


    if not result.stdout:
        raise SystemExit(
            "pokemon-colorscripts returned nothing"
        )


    pixels = parse(
        result.stdout
    )


    pixels, width, height = crop_pixels(
        pixels
    )


    if not pixels:
        raise SystemExit(
            "Could not parse Pokemon pixels"
        )


    svg = build_svg(
        pixels,
        width,
        height,
    )


    SVG_FILE.write_text(
        svg,
        encoding="utf-8",
    )


    subprocess.run(
        [
            "magick",
            "-background",
            "none",

            str(SVG_FILE),

            "-filter",
            "point",

            str(PNG_FILE),
        ],
        check=True,
        timeout=10,
    )


    print(
        f"{PNG_FILE} "
        f"({width}x{height})"
    )


if __name__ == "__main__":
    main()
