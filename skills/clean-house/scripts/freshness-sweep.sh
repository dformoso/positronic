#!/usr/bin/env bash
# Freshness sweep over the dated decision files (definitions/infrastructure.md,
# definitions/decisions.md, definitions/runtime.md).
# Output: PAST-DUE for every NEXT REVIEW date before today; MALFORMED for a NEXT REVIEW
# line with no parseable date; TRIGGER for every armed trigger line — whether a trigger
# has fired is a judgment call, so the caller reads those.
today=$(date +%F)
files="definitions/infrastructure.md definitions/decisions.md definitions/runtime.md"
grep -n 'NEXT REVIEW:' $files 2>/dev/null | while IFS= read -r hit; do
  due=$(printf '%s\n' "$hit" | sed -nE 's/.*NEXT REVIEW:[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p')
  if [ -z "$due" ]; then
    printf 'MALFORMED %s\n' "$hit"
  elif [[ "$due" < "$today" ]]; then
    printf 'PAST-DUE  %s\n' "$hit"
  fi
done
grep -nE '^[-*[:space:]]*TRIGGER:' $files 2>/dev/null | sed 's/^/TRIGGER   /'
exit 0
