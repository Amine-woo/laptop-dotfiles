#!/usr/bin/env python3

import re
import subprocess
import time
import sys

MIN_DISPLAY_INTERVAL = 0.04

last_volume = None
last_muted = None
last_display_time = 0.0


def get_volume():
    try:
        result = subprocess.run(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
            capture_output=True,
            text=True,
            timeout=1,
        )

        text = result.stdout.strip()

        match = re.search(r"Volume:\s*([0-9.]+)", text)

        if not match:
            return None, None

        volume = float(match.group(1))
        muted = "[MUTED]" in text

        return volume, muted

    except Exception:
        return None, None


def volume_icon(volume, muted):
    if muted or volume <= 0.01:
        return "audio-volume-muted-symbolic"

    if volume < 0.34:
        return "audio-volume-low-symbolic"

    if volume < 0.67:
        return "audio-volume-medium-symbolic"

    return "audio-volume-high-symbolic"


def show_osd(volume, muted):
    global last_display_time

    now = time.monotonic()

    if now - last_display_time < MIN_DISPLAY_INTERVAL:
        return

    last_display_time = now

    if muted:
        progress = 0.0
    else:
        progress = max(
            0.0,
            min(1.0, volume)
        )

    icon = volume_icon(volume, muted)

    try:
        subprocess.Popen(
            [
                "swayosd-client",
                "--custom-icon",
                icon,
                "--custom-progress",
                f"{progress:.3f}",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    except Exception:
        pass


def handle_change():
    global last_volume
    global last_muted

    volume, muted = get_volume()

    if volume is None:
        return

    if (
        last_volume is not None
        and abs(volume - last_volume) < 0.001
        and muted == last_muted
    ):
        return

    last_volume = volume
    last_muted = muted

    show_osd(volume, muted)


def watch():
    global last_volume
    global last_muted

    # État initial sans afficher d'OSD
    last_volume, last_muted = get_volume()

    while True:
        try:
            process = subprocess.Popen(
                ["pactl", "subscribe"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )

            if process.stdout is None:
                time.sleep(1)
                continue

            for line in process.stdout:
                if (
                    "Event 'change' on sink" in line
                    or "Event 'new' on sink" in line
                ):
                    # Laisse PipeWire finir de mettre à jour le volume
                    time.sleep(0.015)
                    handle_change()

        except KeyboardInterrupt:
            return

        except Exception as error:
            print(
                f"volume-osd-watch: {error}",
                file=sys.stderr,
                flush=True,
            )

        # Reconnexion si PipeWire/pactl redémarre
        time.sleep(1)


if __name__ == "__main__":
    watch()
