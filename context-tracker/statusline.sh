#!/usr/bin/env bash
# Usage bars for Claude Code's statusLine feature.
# Reads session JSON on stdin (see https://code.claude.com/docs/en/statusline),
# prints one full-width gradient bar per (LABEL, MODE) pair given as arguments.
#
# Usage: statusline.sh [MODE:LABEL]...
#   MODE   One of SESSION | FIVEHOUR | WEEK | SPEND (case-insensitive).
#          Unrecognised or missing values fall back to SESSION.
#   LABEL  Free text shown beside the percentage. Whitespace is kept as-is;
#          anything past 20 characters is cut off. Optional, defaults to "".
#
# With no arguments at all, prints a single unlabeled SESSION bar.
# Each MODE:LABEL argument becomes its own bar, one per line, e.g.:
#   statusline.sh "SESSION:Context" "WEEK:Week"

LABEL_ALIGN="LEFT"
# LABEL_ALIGN=LEFT  ->  "Label |####---| 75%"
# LABEL_ALIGN=RIGHT ->  "|####---| Label 75%"

# Edit GRADIENT_COLORS to change the bars' colours.
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

WIDTH=$(( ${COLUMNS:-80} - 4 ))
(( WIDTH < 10 )) && WIDTH=10

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

# Renders one bar line for a given percentage.
render_bar() {
  local pct=$1
  local label=$2
  local pct_text="${pct}%"

  local align
  align=$(printf '%s' "$LABEL_ALIGN" | tr '[:lower:]' '[:upper:]')

  local inner prefix text
  if [[ "$align" == "LEFT" ]]; then
    prefix=""
    [[ -n "$label" ]] && prefix="${label} "
    # <prefix>|<bar>| <pct_text>  ->  len(prefix) + 1 + inner + 1 + 1 + len(pct_text)
    inner=$(( WIDTH - 3 - ${#prefix} - ${#pct_text} ))
  else
    text="$pct_text"
    [[ -n "$label" ]] && text="${label} ${pct_text}"
    # |<bar>| <text>  ->  1 + inner + 1 + 1 + len(text)
    inner=$(( WIDTH - 3 - ${#text} ))
  fi
  (( inner < 0 )) && inner=0

  local filled=$(( inner * pct / 100 ))
  (( filled > inner )) && filled=$inner
  local empty=$(( inner - filled ))

  local bar=""
  if (( filled > 0 )); then
    local i t
    for (( i = 0; i < filled; i++ )); do
      if (( inner > 1 )); then
        t=$(( i * 100 / (inner - 1) ))
      else
        t=0
      fi
      rgb_at "$t"
      bar+="${ESC}[38;2;${R};${G};${B}m#"
    done
    bar+="$RESET"
  fi

  local dashes=""
  if (( empty > 0 )); then
    printf -v dashes '%*s' "$empty" ''
    dashes=${dashes// /-}
  fi

  if [[ "$align" == "LEFT" ]]; then
    printf '%s|%s%s| %s' "$prefix" "$bar" "$dashes" "$pct_text"
  else
    printf '|%s%s| %s' "$bar" "$dashes" "$text"
  fi
}

# Looks up the jq path for a MODE and echoes the raw percentage (0 if absent).
pct_for_mode() {
  local mode=$1
  case "$mode" in
    FIVEHOUR) echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0' ;;
    WEEK)     echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0' ;;
    SPEND)    echo "$input" | jq -r '.rate_limits.spend_limit.used_percentage // 0' ;;
    *)        echo "$input" | jq -r '.context_window.used_percentage // 0' ;;
  esac
}

# Build bars from MODE:LABEL args; no args at all -> one unlabeled SESSION bar.
if (( $# == 0 )); then
  set -- "SESSION:"
fi

OUTPUT=""
for arg in "$@"; do
  mode="${arg%%:*}"
  label="${arg#*:}"
  mode=$(printf '%s' "${mode:-SESSION}" | tr '[:lower:]' '[:upper:]')
  label="${label:0:20}"

  pct_raw=$(pct_for_mode "$mode")
  pct=$(printf '%.0f' "$pct_raw")

  OUTPUT+="$(render_bar "$pct" "$label")"$'\n'
done

printf '%s' "$OUTPUT"
