# kodi-shutdown-check

## Install
Set Kodi shutdown timer to 5min

* Add kodi-shutdown to /etc/cron.d, runs every 4 mins as root
* Add kodi-shutdown-inhibit.sh and kodi-shutdown-check.sh to /usr/local/bin/

Will inhibit shutdown if:

* Uptime is less than 15min
* Is a weekday an between 9-10 and 19-23, in the weekend it is 7-0
* Transmission is download 1 or more torrents
* Raid check is running
* A file with a name matching /tmp/noshutdown-*.lock exists
* One of the programs: chrome, chromium, fs-uae, popcorntime, dolphine and spotify is running
* A user is logged in

Between 2 and 6 shutdown is allowed even if one of the above conditions are true

## Tested

Works on my system :)
