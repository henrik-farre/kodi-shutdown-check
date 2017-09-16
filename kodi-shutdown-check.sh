#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

# Check time
HOUR=$(date '+%-k')
MIN=$(date +%M)
DAY=$(date '+%u')

case ${DAY} in
  1|2|3|4|5) # Work days
  ONHOURS="9 10 19 20 21 22 23"
  ;;
  6|7) # Weekends
  ONHOURS="0 1 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23"
  ;;
esac

UPTIME_IN_MIN=$(awk '{print $0/60;}' /proc/uptime)
if [[ "${UPTIME_IN_MIN%%.*}" -lt 15 ]]; then
  /usr/bin/logger "$0: Uptime is less than 15 min"
  exit 1
fi

# Hours where shutdown is forced
KILLHOURS="2 3 4 5 6"

for KILLHOUR in ${KILLHOURS}; do
  # Respect backup!
  # if [ -e /tmp/noshutdown-backup-*.lock ]; then
  #   /usr/bin/logger "$0: killhour aborted, backup running: ${HOUR} (day:${DAY})"
  #   exit 1
  # fi
  if [[ "$HOUR" -eq "$KILLHOUR" ]]; then
    /usr/bin/logger "$0: in killhour: ${HOUR} (day:${DAY})"
    exit 0
  fi
done

for ONHOUR in $ONHOURS; do
  if [[ "$HOUR" == "$ONHOUR" ]]; then
    #/usr/bin/logger "$0: in onhour: ${HOUR} (day:${DAY})"
    exit 1
  else
    # Considered true if clock 18:16
    if [[ $(( HOUR + 1 )) == "$ONHOUR" && $MIN -gt 15 ]]; then
      /usr/bin/logger "$0: less than 45min to onhour: $HOUR $MIN $ONHOUR (day:$DAY)"
      exit 1
    fi
  fi
done

if [[ $(transmission-remote -l | wc -l) -gt 2 ]]; then
  /usr/bin/logger "$0: transmission downloading"
  exit 1
fi

if [[ $(grep -c "check" /proc/mdstat) = 1 ]]; then
  /usr/bin/logger "$0: raid resync is running"
  exit 1
fi

# SC2144
for file in /tmp/noshutdown-*.lock
do
  if [ -e "$file" ]
  then
    /usr/bin/logger "$0: a job is running: $file"
    exit 1
  fi
done

declare -a CHECK_PROGRAMS
CHECK_PROGRAMS=('chrome' 'chromium' 'fs-uae' 'popcorntime' 'dolphin' 'spotify')

for PROGRAM in "${CHECK_PROGRAMS[@]}"; do
  if pgrep "$PROGRAM" &>/dev/null; then
    /usr/bin/logger "$0: $PROGRAM is running"
    exit 1
  fi
done

# if last | head | grep -q ".*still logged in"; then
USERS=$(w -h | grep -v mythtv | wc -l)
if [[ $USERS -gt 0 ]]; then
  # Der er en bruger logget ind
  /usr/bin/logger "$0: user logged in"
  exit 1
fi

/usr/bin/logger "$0: shutdown ok"
exit 0
