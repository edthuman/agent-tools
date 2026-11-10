#!/usr/bin/env bash
# Context window usage bar for Claude Code's statusLine feature.
# Reads session JSON on stdin (see https://code.claude.com/docs/en/statusline),
# prints a full-width bar with a colour gradient, with the live percent on the right.
#
# Edit GRADIENT_COLORS to change the bar's colours.
# Hex RGB strings are spaced evenly from 0 % (left) to 100 % (right).
# Duplicate the last entry to hold a colour flat over the final segment.
GRADIENT_COLORS=(
  "00ff00"
  "ffff00"
  "ff0000"
  "800080"
  "00008b"
  "00008b"
)

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

rgb_at() {
  local t=$1
  (( t < 0 )) && t=0
  (( t > 100 )) && t=100

  local n=${#GRADIENT_COLORS[@]}
  if (( n == 0 )); then R=255; G=255; B=255; return; fi
  if (( n == 1 )); then
    local hex=${GRADIENT_COLORS[0]}
    R=$(( 16#${hex:0:2} )); G=$(( 16#${hex:2:2} )); B=$(( 16#${hex:4:2} ))
    return
  fi

  local segments=$(( n - 1 ))
  local seg=$(( t * segments / 100 ))
  (( seg >= segments )) && seg=$(( segments - 1 ))

  local seg_lo=$(( seg * 100 / segments ))
  local seg_hi=$(( (seg + 1) * 100 / segments ))
  local seg_range=$(( seg_hi - seg_lo ))

  local hex_lo=${GRADIENT_COLORS[$seg]}
  local hex_hi=${GRADIENT_COLORS[$((seg + 1))]}
  local lo_r=$(( 16#${hex_lo:0:2} )) lo_g=$(( 16#${hex_lo:2:2} )) lo_b=$(( 16#${hex_lo:4:2} ))
  local hi_r=$(( 16#${hex_hi:0:2} )) hi_g=$(( 16#${hex_hi:2:2} )) hi_b=$(( 16#${hex_hi:4:2} ))

  if (( seg_range == 0 )); then
    R=$lo_r; G=$lo_g; B=$lo_b
  else
    R=$(( lo_r + (hi_r - lo_r) * (t - seg_lo) / seg_range ))
    G=$(( lo_g + (hi_g - lo_g) * (t - seg_lo) / seg_range ))
    B=$(( lo_b + (hi_b - lo_b) * (t - seg_lo) / seg_range ))
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
