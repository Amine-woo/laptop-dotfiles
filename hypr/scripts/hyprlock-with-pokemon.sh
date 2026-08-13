#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/hyprlock-pokemon"
RUNTIME_CONF="$CACHE_DIR/hyprlock-runtime.conf"
BASE_CONF="$HOME/.config/hypr/hyprlock.conf"
POKE_CONF="$HOME/.config/hypr/hyprlock-pokemon.conf"

mkdir -p "$CACHE_DIR"

# Nettoie les anciens fichiers
find "$CACHE_DIR" -type f -name 'pokemon-*.png' -mmin +10 -delete 2>/dev/null || true

# Rafraîchit les couleurs pywal de hyprlock
"$HOME/.config/hypr/scripts/gen-hyprlock-pywal.sh" >/dev/null 2>&1 || true

# Génère d'abord le pokemon habituel
"$HOME/.config/hypr/scripts/render-hyprlock-pokemon.py" >/tmp/hyprlock-pokemon.log 2>&1

# Nom UNIQUE pour éviter tout cache Hyprlock
UNIQUE_PNG="$CACHE_DIR/pokemon-$(date +%s%N)-$RANDOM.png"

cp "$HOME/.cache/hyprlock-pokemon.png" "$UNIQUE_PNG"

# Crée une copie runtime de la config principale,
# sans inclure l'ancien hyprlock-pokemon.conf
grep -vF 'source = ~/.config/hypr/hyprlock-pokemon.conf' \
    "$BASE_CONF" > "$RUNTIME_CONF"

# Ajoute le pokemon avec son chemin UNIQUE
cat >> "$RUNTIME_CONF" <<EOF2

# ===== RANDOM COLORED PIXEL POKEMON =====

image {
    monitor =

    path = $UNIQUE_PNG

    size = 350

    rounding = 0
    border_size = 0
    rotate = 0

    position = -650, -10

    halign = center
    valign = center
}
EOF2

# Lance hyprlock avec CETTE config spécifique
exec /usr/bin/hyprlock -c "$RUNTIME_CONF"
