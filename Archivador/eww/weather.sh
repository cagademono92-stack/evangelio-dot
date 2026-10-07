#!/usr/bin/env bash
# Clima actual: icono/emoji + temperatura + condición, línea única
raw=$(curl -s --max-time 15 "wttr.in/?format=%C|%t|%f")
if [ -z "$raw" ]; then echo "☁ --°C"; exit 0; fi
cond=$(echo "$raw" | cut -d'|' -f1)
temp=$(echo "$raw" | cut -d'|' -f2)
feels=$(echo "$raw" | cut -d'|' -f3)
case "$cond" in
  *Sun?*|*Clear*) icon="☀" ;;
  *Cloud*|*Overcast*) icon="☁" ;;
  *Rain*|*Drizzle*|*Shower*) icon="🌧" ;;
  *Snow*) icon="❄" ;;
  *Thunder*) icon="⛈" ;;
  *Fog*|*Mist*) icon="🌫" ;;
  *) icon="🌤" ;;
esac
echo "$icon $temp  (sensación $feels)"
