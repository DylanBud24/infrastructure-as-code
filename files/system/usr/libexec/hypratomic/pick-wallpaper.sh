#!/usr/bin/env bash
#
# rofi-based wallpaper picker. Scans ~/Pictures/wallpapers/, lets you pick,
# applies via hyprpaper, and rewrites ~/.config/hypr/hyprpaper.conf so the
# choice survives restarts.
set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/wallpapers"
if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    notify-send -a Wallpaper "Wallpapers folder created" \
        "Drop images in $dir and run this again."
    exit 0
fi

pick=$(find "$dir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -printf '%f\n' | sort | rofi -dmenu -p "Wallpaper")
[[ -z "$pick" ]] && exit 0

file="$dir/$pick"

# Apply live.
hyprctl hyprpaper preload "$file" >/dev/null
hyprctl hyprpaper wallpaper ",$file" >/dev/null

# Persist across restarts — rewrite the preload/wallpaper lines in hyprpaper.conf.
conf="$HOME/.config/hypr/hyprpaper.conf"
if [[ -f "$conf" ]]; then
    tmp=$(mktemp)
    grep -vE '^\s*(preload|wallpaper)\s*=' "$conf" > "$tmp"
    {
        echo ""
        echo "preload = $file"
        echo "wallpaper = ,$file"
    } >> "$tmp"
    mv "$tmp" "$conf"
fi

notify-send -a Wallpaper "Wallpaper set" "$pick"
