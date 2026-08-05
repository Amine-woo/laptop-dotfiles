#!/usr/bin/env python3

import sys
import re
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gtk, GLib, Gio
from gi.repository import Gtk4LayerShell


# ============================================================
# CONFIG
# ============================================================

THRESHOLDS = [20, 10, 5]

CHECK_INTERVAL_SECONDS = 5
DISPLAY_TIME_MS = 3000

PYWAL_COLORS = Path.home() / ".cache/wal/colors.sh"

RED = "#ff3b30"

# Same general position as current OSD
TOP_MARGIN = 90


# ============================================================
# BATTERY
# ============================================================

def find_battery():
    power_dir = Path("/sys/class/power_supply")

    for battery in sorted(power_dir.glob("BAT*")):
        try:
            battery_type = (battery / "type").read_text().strip()
        except Exception:
            battery_type = "Battery"

        if battery_type == "Battery":
            return battery

    return None


BATTERY = find_battery()


def read_battery():
    if BATTERY is None:
        return None, None

    try:
        capacity = int((BATTERY / "capacity").read_text().strip())
        status = (BATTERY / "status").read_text().strip()

        return capacity, status

    except Exception:
        return None, None


# ============================================================
# PYWAL
# ============================================================

def read_pywal():
    colors = {
        "background": "#111111",
        "foreground": "#ffffff",
        "color8": "#777777",
    }

    try:
        text = PYWAL_COLORS.read_text()

        for key in colors:
            match = re.search(
                rf"^{key}=['\"]([^'\"]+)['\"]",
                text,
                re.MULTILINE,
            )

            if match:
                colors[key] = match.group(1)

    except Exception:
        pass

    return colors


def hex_to_rgb(hex_color):
    value = hex_color.lstrip("#")

    try:
        return (
            int(value[0:2], 16),
            int(value[2:4], 16),
            int(value[4:6], 16),
        )

    except Exception:
        return 17, 17, 17


# ============================================================
# OSD
# ============================================================

class BatteryWindow(Gtk.ApplicationWindow):

    def __init__(self, app):
        super().__init__(application=app)

        self.set_name("battery-osd-window")
        self.set_decorated(False)
        self.set_resizable(False)

        Gtk4LayerShell.init_for_window(self)

        Gtk4LayerShell.set_layer(
            self,
            Gtk4LayerShell.Layer.OVERLAY,
        )

        Gtk4LayerShell.set_keyboard_mode(
            self,
            Gtk4LayerShell.KeyboardMode.NONE,
        )

        Gtk4LayerShell.set_anchor(
            self,
            Gtk4LayerShell.Edge.TOP,
            True,
        )

        Gtk4LayerShell.set_margin(
            self,
            Gtk4LayerShell.Edge.TOP,
            TOP_MARGIN,
        )

        Gtk4LayerShell.set_namespace(
            self,
            "amine-battery-osd",
        )

        self.css_provider = Gtk.CssProvider()

        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            self.css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        # Main card
        self.card = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=16,
        )

        self.card.add_css_class("battery-card")

        # Icon
        self.icon = Gtk.Label(label="⚠")
        self.icon.add_css_class("battery-icon")

        self.card.append(self.icon)

        # Text area
        right = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=7,
        )

        header = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=14,
        )

        self.title = Gtk.Label()
        self.title.set_xalign(0)
        self.title.set_hexpand(True)
        self.title.add_css_class("battery-title")

        self.percent = Gtk.Label()
        self.percent.add_css_class("battery-percent")

        header.append(self.title)
        header.append(self.percent)

        self.subtitle = Gtk.Label()
        self.subtitle.set_xalign(0)
        self.subtitle.add_css_class("battery-subtitle")

        self.progress = Gtk.ProgressBar()
        self.progress.add_css_class("battery-progress")
        self.progress.set_hexpand(True)

        right.append(header)
        right.append(self.subtitle)
        right.append(self.progress)

        self.card.append(right)

        self.set_child(self.card)

        self.hide_timer = None
        self.blink_timer = None
        self.flash_on = False


    # ========================================================
    # CSS
    # ========================================================

    def update_css(self):
        colors = read_pywal()

        background = colors["background"]
        foreground = colors["foreground"]
        color8 = colors["color8"]

        br, bg, bb = hex_to_rgb(background)
        r8, g8, b8 = hex_to_rgb(color8)

        css = f"""
window#battery-osd-window {{
    background-color: transparent;
}}

.battery-card {{
    min-width: 390px;

    padding: 14px 18px;

    border-radius: 18px;

    border: 2px solid {RED};

    background-color:
        rgba({br}, {bg}, {bb}, 0.88);

    box-shadow:
        0 8px 28px rgba(0, 0, 0, 0.45);
}}


/* =========================================================
   5% CRITICAL FLASH
   ========================================================= */

.battery-card.critical-flash {{
    background-color:
        rgba(255, 59, 48, 0.48);

    border: 2px solid #ff453a;

    box-shadow:
        0 0 24px rgba(255, 59, 48, 0.75),
        0 8px 28px rgba(0, 0, 0, 0.45);
}}


.battery-icon {{
    color: {RED};

    font-family:
        "JetBrainsMono Nerd Font Propo",
        "JetBrainsMono Nerd Font",
        sans-serif;

    font-size: 31px;
    font-weight: bold;
}}


.battery-title {{
    color: {foreground};

    font-family:
        "JetBrainsMono Nerd Font Propo",
        "JetBrainsMono Nerd Font",
        sans-serif;

    font-size: 16px;
    font-weight: 700;
}}


.battery-percent {{
    color: {RED};

    font-family:
        "JetBrainsMono Nerd Font Propo",
        "JetBrainsMono Nerd Font",
        sans-serif;

    font-size: 17px;
    font-weight: 800;
}}


.battery-subtitle {{
    color: {foreground};

    opacity: 0.72;

    font-family:
        "JetBrainsMono Nerd Font Propo",
        "JetBrainsMono Nerd Font",
        sans-serif;

    font-size: 12px;
}}


progressbar.battery-progress {{
    min-height: 8px;
}}


progressbar.battery-progress trough {{
    min-height: 8px;

    border-radius: 999px;

    background-color:
        rgba({r8}, {g8}, {b8}, 0.35);

    border: none;
}}


progressbar.battery-progress progress {{
    min-height: 8px;

    border-radius: 999px;

    background-color: {RED};

    border: none;
}}
"""

        self.css_provider.load_from_data(
            css.encode()
        )


    # ========================================================
    # TIMERS
    # ========================================================

    def stop_timers(self):

        if self.hide_timer is not None:
            try:
                GLib.source_remove(
                    self.hide_timer
                )
            except Exception:
                pass

            self.hide_timer = None


        if self.blink_timer is not None:
            try:
                GLib.source_remove(
                    self.blink_timer
                )
            except Exception:
                pass

            self.blink_timer = None


        self.card.remove_css_class(
            "critical-flash"
        )

        self.flash_on = False


    def hide_osd(self):
        self.stop_timers()

        self.set_visible(False)

        return False


    # ========================================================
    # TRUE RED FLASH
    # ========================================================

    def blink_red(self):

        self.flash_on = not self.flash_on

        if self.flash_on:
            self.card.add_css_class(
                "critical-flash"
            )
        else:
            self.card.remove_css_class(
                "critical-flash"
            )

        return True


    # ========================================================
    # SHOW ALERT
    # ========================================================

    def show_alert(
        self,
        threshold,
        capacity=None,
    ):

        if capacity is None:
            capacity = threshold

        self.stop_timers()
        self.update_css()


        if threshold == 20:

            title = "Low battery"

            subtitle = (
                "Connect your charger soon"
            )


        elif threshold == 10:

            title = "Battery critical"

            subtitle = (
                "Connect your charger"
            )


        else:

            title = "Battery almost empty"

            subtitle = (
                "Connect your charger now"
            )


        self.title.set_text(title)

        self.percent.set_text(
            f"{capacity}%"
        )

        self.subtitle.set_text(
            subtitle
        )

        self.progress.set_fraction(
            max(
                0.0,
                min(
                    1.0,
                    capacity / 100.0,
                )
            )
        )

        self.present()


        # ====================================================
        # 5% ONLY: FLASH THE CARD RED
        # ====================================================

        if threshold == 5:

            self.blink_timer = GLib.timeout_add(
                300,
                self.blink_red,
            )


        # Every warning stays 3 seconds
        self.hide_timer = GLib.timeout_add(
            DISPLAY_TIME_MS,
            self.hide_osd,
        )


# ============================================================
# BATTERY WATCHER
# ============================================================

class BatteryWatcher:

    def __init__(self, window):

        self.window = window

        self.last_capacity = None

        self.was_discharging = False

        self.notified = set()


    def mark_previous_thresholds(
        self,
        threshold,
    ):

        for value in THRESHOLDS:

            if value >= threshold:
                self.notified.add(
                    value
                )


    def initial_alert(
        self,
        capacity,
    ):

        available = [
            threshold
            for threshold in THRESHOLDS
            if capacity <= threshold
        ]

        if not available:
            return


        threshold = min(
            available,
            key=lambda value:
                value - capacity,
        )


        self.mark_previous_thresholds(
            threshold
        )


        self.window.show_alert(
            threshold,
            capacity,
        )


    def check(self):

        capacity, status = read_battery()


        if capacity is None or status is None:
            return True


        # Charger connected:
        # reset warnings for next discharge.
        if status != "Discharging":

            self.notified.clear()

            self.last_capacity = capacity

            self.was_discharging = False

            return True


        # Started discharging
        if not self.was_discharging:

            self.was_discharging = True

            self.last_capacity = capacity

            self.initial_alert(
                capacity
            )

            return True


        previous = self.last_capacity


        if (
            previous is not None
            and capacity < previous
        ):

            crossed = [
                threshold
                for threshold in THRESHOLDS

                if (
                    capacity <= threshold < previous

                    and threshold
                    not in self.notified
                )
            ]


            if crossed:

                threshold = min(
                    crossed
                )

                self.mark_previous_thresholds(
                    threshold
                )

                self.window.show_alert(
                    threshold,
                    capacity,
                )


        self.last_capacity = capacity

        return True


# ============================================================
# GTK APP
# ============================================================

class BatteryApplication(Gtk.Application):

    def __init__(
        self,
        test_threshold=None,
    ):

        super().__init__(
            application_id=(
                "dev.amine.BatteryOSD"
            ),

            flags=(
                Gio.ApplicationFlags.NON_UNIQUE
            ),
        )

        self.test_threshold = (
            test_threshold
        )

        self.window = None
        self.watcher = None


    def do_activate(self):

        self.window = BatteryWindow(
            self
        )


        # Test mode
        if self.test_threshold is not None:

            self.window.show_alert(
                self.test_threshold,
                self.test_threshold,
            )

            GLib.timeout_add(
                DISPLAY_TIME_MS + 300,
                self.quit,
            )

            return


        # Daemon mode
        self.hold()


        self.watcher = BatteryWatcher(
            self.window
        )


        # Immediate battery check
        self.watcher.check()


        # Check every 5 seconds
        GLib.timeout_add_seconds(
            CHECK_INTERVAL_SECONDS,
            self.watcher.check,
        )


# ============================================================
# MAIN
# ============================================================

def main():

    test_threshold = None


    if (
        len(sys.argv) >= 3
        and sys.argv[1] == "--test"
    ):

        try:

            test_threshold = int(
                sys.argv[2]
            )

        except ValueError:

            print(
                "Usage: battery-osd.py "
                "--test 20|10|5"
            )

            return 1


        if test_threshold not in THRESHOLDS:

            print(
                "Usage: battery-osd.py "
                "--test 20|10|5"
            )

            return 1


    app = BatteryApplication(
        test_threshold=test_threshold
    )


    return app.run([])


if __name__ == "__main__":
    raise SystemExit(
        main()
    )
