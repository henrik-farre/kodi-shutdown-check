#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

# based on http://forum.xbmc.org/showthread.php?tid=172801&pid=1500080#pid1500080

LAST_STATE_FILE="/tmp/kodi-shutdown-inibit.laststate"
KODI_PID_FILE="/tmp/kodi-shutdown-inibit.pid"

# Handle restart of xbmc
KODI_NOT_RUNNING=0
if ! CURRENT_PID=$(pgrep kodi.bin); then
  KODI_NOT_RUNNING=1
fi

if [[ -f $KODI_PID_FILE ]]; then
  PID=$(cat $KODI_PID_FILE)
else
  PID=$CURRENT_PID
  echo "$PID" > "$KODI_PID_FILE"
fi

# if the old pid is not equal to the current, make sure that inhibit is send again
# by forcing it to be 0
if [[ "$PID" != "$CURRENT_PID" ]]; then
  /usr/bin/logger "$0: KODI changed PID: $PID != $CURRENT_PID"
  if [[ -f $LAST_STATE_FILE ]]; then
    rm "$LAST_STATE_FILE"
  fi
  echo "$CURRENT_PID" > "$KODI_PID_FILE"
fi

# Disabled here, and in the script
#/usr/local/bin/set-next-wakeup.sh &>/dev/null

# Remember state to avoid sending same event multiple times
if [[ -f $LAST_STATE_FILE ]]; then
  LAST_STATE=$(cat $LAST_STATE_FILE)
else
  LAST_STATE=0
fi

/usr/local/bin/kodi-shutdown-check.sh &>/dev/null
CHECK=$?

/usr/bin/logger "$0: [DEBUG] CHECK: ${CHECK} \
 [DEBUG] LAST_STATE: ${LAST_STATE} \
 [DEBUG] KODI_NOT_RUNNING: ${KODI_NOT_RUNNING} \
 [DEBUG] PID: ${PID} \
 [DEBUG] CURRENT_PID: ${CURRENT_PID}"

# 0: Shutdown allowed
if [[ $CHECK -eq 0 ]]; then
  if [[ $KODI_NOT_RUNNING -gt 0 ]]; then
    /usr/bin/logger "$0: Kodi not running, shutting down"
    /usr/bin/shutdown -h now
  fi
  if [[ $LAST_STATE -ne 0 ]]; then
    kodi-send --action="XBMC.InhibitIdleShutdown(false)" >/dev/null
    /usr/bin/logger "$0: Allow shutdown"
    echo "0" > $LAST_STATE_FILE
#  else
#    /usr/bin/logger "$0: Shutdown allready allowed"
  fi
else
  if [[ $LAST_STATE -eq 0 ]]; then
    kodi-send --action="XBMC.InhibitIdleShutdown(true)" >/dev/null
    /usr/bin/logger "$0: Inhibit shutdown"
    echo "1" > $LAST_STATE_FILE
#  else
#    /usr/bin/logger "$0: Shutdown allready inhibited"
  fi
fi
