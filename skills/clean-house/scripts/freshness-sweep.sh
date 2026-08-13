#!/usr/bin/env bash
# Freshness sweep over dated decision records (docs/adr/, definitions/runtime.md).
# Output: PAST-DUE for every NEXT REVIEW date before today; MALFORMED for a NEXT REVIEW
# line with no parseable date; TRIGGER for every armed trigger line — whether a trigger
# has fired is a judgment call, so the caller reads those.
today=$(date +%F)
grep -rn 'NEXT REVIEW:' docs/adr definitions/runtime.md 2>/dev/null | while IFS= read -r hit; do
  due=$(printf '%s\n' "$hit" | sed -nE 's/.*NEXT REVIEW:[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p')
  if [ -z "$due" ]; then
    printf 'MALFORMED %s\n' "$hit"
  elif [[ "$due" < "$today" ]]; then
    printf 'PAST-DUE  %s\n' "$hit"
  fi
done
grep -rnE '^[-*[:space:]]*TRIGGER:' docs/adr definitions/runtime.md 2>/dev/null | sed 's/^/TRIGGER   /'
exit 0
