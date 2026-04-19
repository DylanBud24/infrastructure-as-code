#!/usr/bin/env bash
#
# Toggle between dual-monitor and TV modes.
#
# Layout:
#   DP-2     = 1440p left monitor
#   HDMI-A-1 = 1440p right monitor (via KVM)
#   DP-1     = 4K TV (via UGREEN DP-to-HDMI adapter)
#
# Ported from the KDE kscreen-doctor version in ~/Scripts/.
set -euo pipefail

# hyprctl monitors only lists enabled outputs, so DP-1 being present = TV on.
tv_on=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .name' || true)

if [[ -n "$tv_on" ]]; then
    hyprctl --batch "\
        keyword monitor DP-2,2560x1440@144,0x0,1 ; \
        keyword monitor HDMI-A-1,2560x1440@120,2560x0,1,vrr,0 ; \
        keyword monitor DP-1,disable"
    notify-send -a Display "Dual monitors" "DP-2 + HDMI-A-1 on, TV off"
else
    hyprctl --batch "\
        keyword monitor DP-2,disable ; \
        keyword monitor HDMI-A-1,disable ; \
        keyword monitor DP-1,preferred,auto,1"
    notify-send -a Display "TV mode" "Monitors off, DP-1 on"
fi
