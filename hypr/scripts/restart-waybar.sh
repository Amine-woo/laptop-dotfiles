#!/usr/bin/env bash

setsid -f bash -c '
  sleep 0.15

  pkill -x waybar

  while pgrep -x waybar >/dev/null; do
    sleep 0.1
  done

  sleep 0.25

  waybar >/tmp/waybar.log 2>&1
'