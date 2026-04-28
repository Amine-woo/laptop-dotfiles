#!/usr/bin/env bash

if hyprctl monitors | grep -q "^Monitor DP-1 "; then
  hyprctl dispatch moveworkspacetomonitor 1 DP-1
  hyprctl dispatch moveworkspacetomonitor 2 DP-1
  hyprctl dispatch moveworkspacetomonitor 3 DP-1
  hyprctl dispatch moveworkspacetomonitor 4 DP-1
  hyprctl dispatch moveworkspacetomonitor 5 DP-1
  hyprctl dispatch moveworkspacetomonitor 6 DP-1
  hyprctl dispatch moveworkspacetomonitor 7 DP-1
  hyprctl dispatch moveworkspacetomonitor 8 DP-1

  hyprctl dispatch moveworkspacetomonitor 9 eDP-1
  hyprctl dispatch moveworkspacetomonitor 10 eDP-1

  hyprctl dispatch focusmonitor DP-1
  hyprctl dispatch workspace 1
else
  hyprctl dispatch moveworkspacetomonitor 1 eDP-1
  hyprctl dispatch moveworkspacetomonitor 2 eDP-1
  hyprctl dispatch moveworkspacetomonitor 3 eDP-1
  hyprctl dispatch moveworkspacetomonitor 4 eDP-1
  hyprctl dispatch moveworkspacetomonitor 5 eDP-1
  hyprctl dispatch moveworkspacetomonitor 6 eDP-1
  hyprctl dispatch moveworkspacetomonitor 7 eDP-1
  hyprctl dispatch moveworkspacetomonitor 8 eDP-1
  hyprctl dispatch moveworkspacetomonitor 9 eDP-1
  hyprctl dispatch moveworkspacetomonitor 10 eDP-1

  hyprctl dispatch focusmonitor eDP-1
  hyprctl dispatch workspace 1
fi