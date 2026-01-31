#!/bin/sh
set -eu
 
# Choose an output: prefer an external monitor (non eDP/LVDS), otherwise use the internal display
OUT=$(xrandr --query | awk '
/ connected/ {
  name=$1
  if (name !~ /^(eDP|LVDS)/) ext=name
  if (name ~ /^(eDP|LVDS)/) int=name
}
END {
  if (ext != "") print ext; else print int
}')
 
[ -n "$OUT" ] || exit 1
 
# Select the highest resolution and highest refresh rate for the chosen output
MODE_RATE=$(xrandr --query | awk -v out="$OUT" '
$1==out {in=1; next}
in && /^[A-Za-z0-9]/ {in=0}
in && /^[ ]/ {
  mode=$1
  for (i=2;i<=NF;i++) {
    gsub(/\*/,"",$i)
    if ($i+0>0) {
      rate=$i
      # Prefer larger resolution; if equal, prefer higher refresh rate
      split(mode, m, "x"); pixels=m[1]*m[2]
      if (pixels>bestp || (pixels==bestp && rate>bestr)) {
        bestp=pixels; bestr=rate; bestm=mode
      }
    }
  }
}
END {if (bestm!="") print bestm, bestr}
')
 
MODE=$(printf "%s" "$MODE_RATE" | awk '{print $1}')
RATE=$(printf "%s" "$MODE_RATE" | awk '{print $2}')
 
xrandr --output "$OUT" --primary --mode "$MODE" --rate "$RATE" --auto
