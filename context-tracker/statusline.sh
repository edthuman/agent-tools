#!/usr/bin/env bash
# Context window usage bar for Claude Code's statusLine feature.
# Reads session JSON on stdin (see https://code.claude.com/docs/en/statusline),
# prints a full-width bar: green -> yellow -> red -> purple -> dark blue,
# each color owning 20 percentage points, with the live percent on the right.

input=$(cat)

PCT_RAW=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
PCT=$(printf '%.0f' "$PCT_RAW")

WIDTH=$(( ${COLUMNS:-80} - 4 ))
(( WIDTH < 10 )) && WIDTH=10
LABEL="${PCT}%"

# |<bar>| <label>  ->  1 + inner + 1 + 1 + len(label)
INNER=$(( WIDTH - 3 - ${#LABEL} ))
(( INNER < 0 )) && INNER=0

FILLED=$(( INNER * PCT / 100 ))
(( FILLED > INNER )) && FILLED=$INNER
EMPTY=$(( INNER - FILLED ))

ESC=$'\033'
RESET="${ESC}[0m"

# RGB color stops at t = 0, 20, 40, 60, 80, 100
rgb_at() {
  local t=$1
  (( t < 0 )) && t=0
  (( t > 100 )) && t=100

  local lo_t hi_t lo_r lo_g lo_b hi_r hi_g hi_b
  if   (( t <= 20 )); then lo_t=0;  hi_t=20;  lo_r=0;   lo_g=255; lo_b=0;   hi_r=255; hi_g=255; hi_b=0
  elif (( t <= 40 )); then lo_t=20; hi_t=40;  lo_r=255; lo_g=255; lo_b=0;   hi_r=255; hi_g=0;   hi_b=0
  elif (( t <= 60 )); then lo_t=40; hi_t=60;  lo_r=255; lo_g=0;   lo_b=0;   hi_r=128; hi_g=0;   hi_b=128
  elif (( t <= 80 )); then lo_t=60; hi_t=80;  lo_r=128; lo_g=0;   lo_b=128; hi_r=0;   hi_g=0;   hi_b=139
  else                     lo_t=80; hi_t=100; lo_r=0;   lo_g=0;   lo_b=139; hi_r=0;   hi_g=0;   hi_b=139
  fi

  local range=$(( hi_t - lo_t ))
  if (( range == 0 )); then
    R=$lo_r; G=$lo_g; B=$lo_b
  else
    R=$(( lo_r + (hi_r - lo_r) * (t - lo_t) / range ))
    G=$(( lo_g + (hi_g - lo_g) * (t - lo_t) / range ))
    B=$(( lo_b + (hi_b - lo_b) * (t - lo_t) / range ))
  fi
}

BAR=""
if (( FILLED > 0 )); then
  for (( i = 0; i < FILLED; i++ )); do
    if (( INNER > 1 )); then
      t=$(( i * 100 / (INNER - 1) ))
    else
      t=0
    fi
    rgb_at "$t"
    BAR+="${ESC}[38;2;${R};${G};${B}m#"
  done
  BAR+="$RESET"
fi

DASHES=""
if (( EMPTY > 0 )); then
  printf -v DASHES '%*s' "$EMPTY" ''
  DASHES=${DASHES// /-}
fi

printf '|%s%s| %s\n' "$BAR" "$DASHES" "$LABEL"
