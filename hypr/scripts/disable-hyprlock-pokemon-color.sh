#!/usr/bin/env bash
set -euo pipefail

[ -f ~/.config/hypr/hyprlock.conf.bak-pokemon-color ] && \
cp ~/.config/hypr/hyprlock.conf.bak-pokemon-color \
   ~/.config/hypr/hyprlock.conf

[ -f ~/.config/hypr/hyprland.conf.bak-pokemon-color ] && \
cp ~/.config/hypr/hyprland.conf.bak-pokemon-color \
   ~/.config/hypr/hyprland.conf

[ -f ~/.config/hypr/hypridle.conf.bak-pokemon-color ] && \
cp ~/.config/hypr/hypridle.conf.bak-pokemon-color \
   ~/.config/hypr/hypridle.conf

[ -f ~/.config/hypr/scripts/wallpaper.sh.bak-pokemon-color ] && \
cp ~/.config/hypr/scripts/wallpaper.sh.bak-pokemon-color \
   ~/.config/hypr/scripts/wallpaper.sh

rm -f ~/.config/hypr/hyprlock-pokemon.conf
rm -f ~/.config/hypr/scripts/hyprlock-with-pokemon.sh
rm -f ~/.config/hypr/scripts/render-hyprlock-pokemon.py
rm -f ~/.config/hypr/scripts/gen-hyprlock-pywal.sh

echo "Colored Hyprlock Pokémon disabled and configs restored."
echo "Test with: hyprlock"
