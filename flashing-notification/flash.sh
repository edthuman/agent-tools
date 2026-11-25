#!/usr/bin/env bash

# ============================================================
# Claude Code Attention Flash — iTerm2 / macOS
# ============================================================
# Flashes the background of the terminal that needs attention.
# Only flashes if that terminal is NOT currently in focus.
# Restores original color immediately when the window is focused.
# ============================================================

# --- Configuration ---
FLASH_COLOR="#D48B77"         # Color shown during flash-on phase
FALLBACK_ORIG_COLOR="#1D1D1D" # Used if original color cannot be detected
FLASH_ON_SECS=0.3             # Seconds flash color is shown per cycle
FLASH_OFF_SECS=0.5            # Seconds original color is shown per cycle
TOTAL_FLASH_SECS=10           # Seconds before holding flash color indefinitely

# ----------------------------------------------------------------
# TTY discovery: walk the process tree to find the terminal device.
# Must be called before forking — after backgrounding, the process
# is reparented to launchd and the chain back to the terminal is lost.
# ----------------------------------------------------------------
find_tty() {
    local pid=$$
    while [ "$pid" -gt 1 ]; do
        local tty
        tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
        if [ -n "$tty" ] && [ "$tty" != "??" ] && [ "$tty" != "?" ]; then
            echo "/dev/$tty"
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

# ----------------------------------------------------------------
# Bootstrap: fork into background immediately so the hook returns.
# TTY is discovered now and passed via env var to the background copy.
# ----------------------------------------------------------------
if [ -z "$_CC_FLASH_BG" ]; then
    MY_TTY=$(find_tty)
    if [ -z "$MY_TTY" ]; then
        exit 0
    fi
    export _CC_FLASH_BG=1
    export _CC_FLASH_TTY="$MY_TTY"
    bash "$0" < /dev/null > /dev/null 2>&1 &
    exit 0
fi

MY_TTY="${_CC_FLASH_TTY}"
if [ -z "$MY_TTY" ]; then
    exit 1
fi

# ----------------------------------------------------------------
# Deduplication: one flasher per tty at a time.
# ----------------------------------------------------------------
LOCK_FILE="/tmp/cc-flash-$(echo "$MY_TTY" | tr '/' '-').lock"

if ! ( set -o noclobber; echo "$$" > "$LOCK_FILE" ) 2>/dev/null; then
    OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        exit 0
    fi
    echo "$$" > "$LOCK_FILE"
fi

cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# ----------------------------------------------------------------
# Functions
# ----------------------------------------------------------------

# Returns 0 if our terminal session is currently the front session in iTerm2
is_focused() {
    local front_tty
    front_tty=$(osascript 2>/dev/null << 'EOF'
try
    tell application "System Events"
        if not (frontmost of process "iTerm2") then return ""
    end tell
    tell application "iTerm2"
        return tty of current session of current window
    end tell
end try
return ""
EOF
)
    [ "$front_tty" = "$MY_TTY" ]
}

# Gets the current background color of our iTerm2 session via AppleScript.
# Returns a #RRGGBB hex string.
get_bg_color() {
    local result
    result=$(osascript 2>/dev/null << EOF
tell application "iTerm2"
    set myTTY to "$MY_TTY"
    repeat with w in windows
        repeat with t in tabs of w
            repeat with s in sessions of t
                if tty of s = myTTY then
                    set c to background color of s
                    set r to round (((item 1 of c) * 255) / 65535)
                    set g to round (((item 2 of c) * 255) / 65535)
                    set b to round (((item 3 of c) * 255) / 65535)
                    return (r as string) & "," & (g as string) & "," & (b as string)
                end if
            end repeat
        end repeat
    end repeat
    return ""
end tell
EOF
)
    if [ -z "$result" ]; then
        printf '%s' "$FALLBACK_ORIG_COLOR"
        return
    fi
    local r g b
    IFS=',' read -r r g b <<< "$result"
    printf "#%02X%02X%02X" "$r" "$g" "$b"
}

# Sets the background color by writing an OSC 11 escape to the terminal device.
set_bg_color() {
    printf '\033]11;%s\007' "$1" > "$MY_TTY"
}

# Sleeps in 0.1s steps, checking focus after each step.
# Returns 0 (stops early) if focus is gained; 1 if duration completes normally.
sleep_checking_focus() {
    local duration=$1
    local steps
    steps=$(awk "BEGIN { print int($duration * 10 + 0.5) }")
    local i=0
    while [ "$i" -lt "$steps" ]; do
        sleep 0.1
        if is_focused; then
            return 0
        fi
        i=$((i + 1))
    done
    return 1
}

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------

# Only flash if this terminal is not currently in focus
if is_focused; then
    exit 0
fi

# Capture the original background color before touching anything
ORIG_COLOR=$(get_bg_color)

START_TIME=$(date +%s)

while true; do
    ELAPSED=$(( $(date +%s) - START_TIME ))

    # Once TOTAL_FLASH_SECS is reached, hold at flash color and wait for focus
    if [ "$ELAPSED" -ge "$TOTAL_FLASH_SECS" ]; then
        set_bg_color "$FLASH_COLOR"
        while true; do
            sleep 0.3
            if is_focused; then
                set_bg_color "$ORIG_COLOR"
                exit 0
            fi
        done
    fi

    # Flash ON phase
    set_bg_color "$FLASH_COLOR"
    if sleep_checking_focus "$FLASH_ON_SECS"; then
        set_bg_color "$ORIG_COLOR"
        exit 0
    fi

    # Flash OFF phase
    set_bg_color "$ORIG_COLOR"
    if sleep_checking_focus "$FLASH_OFF_SECS"; then
        exit 0
    fi
done
