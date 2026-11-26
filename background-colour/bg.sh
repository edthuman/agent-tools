#!/usr/bin/env bash

# ============================================================
# Terminal Background Colour — iTerm2 / macOS
# ============================================================
# Usage: bg.sh <red|orange|yellow|green|blue|indigo|violet|default>
# Also invoked via symlinks named bgr, bgo, bgy, bgg, bgb, bgi, bgv, bgd
# (created by install.sh). The colour is taken from the argument,
# or from the last letter of the command name if no argument is given.
# ============================================================

# --- Configuration (muted shades that keep light text readable) ---
RED="#5C1A1A"
ORANGE="#853A00"
YELLOW="#6E5900"
GREEN="#1A4A24"
BLUE="#1A2F5C"
INDIGO="#2A1A5C"
VIOLET="#4A1A5C"

colour="$1"
if [ -z "$colour" ]; then
    case "$(basename "$0")" in
        bgr) colour=red ;;
        bgo) colour=orange ;;
        bgy) colour=yellow ;;
        bgg) colour=green ;;
        bgb) colour=blue ;;
        bgi) colour=indigo ;;
        bgv) colour=violet ;;
        bgd) colour=default ;;
    esac
fi

case "$colour" in
    red)     hex="$RED" ;;
    orange)  hex="$ORANGE" ;;
    yellow)  hex="$YELLOW" ;;
    green)   hex="$GREEN" ;;
    blue)    hex="$BLUE" ;;
    indigo)  hex="$INDIGO" ;;
    violet)  hex="$VIOLET" ;;
    default) hex="" ;;
    *)
        echo "Usage: bg.sh <red|orange|yellow|green|blue|indigo|violet|default>" >&2
        exit 1
        ;;
esac

# Find a terminal to write to. /dev/tty works in a normal shell, but
# processes launched by tools like Claude Code have no controlling terminal,
# so fall back to the nearest parent process that is attached to one.
find_tty() {
    if (: > /dev/tty) 2>/dev/null; then
        echo /dev/tty
        return
    fi
    local pid=$$ t
    while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
        t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
        if [ -n "$t" ] && [ "$t" != "??" ] && [ -w "/dev/$t" ]; then
            echo "/dev/$t"
            return
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
}

target=$(find_tty)
if [ -z "$target" ]; then
    echo "bg.sh: could not find a terminal to write to" >&2
    exit 1
fi

if [ -n "$hex" ]; then
    # OSC 11: set background colour
    printf '\033]11;%s\007' "$hex" > "$target"
else
    # OSC 111: reset background to the profile's default
    printf '\033]111\007' > "$target"
fi
