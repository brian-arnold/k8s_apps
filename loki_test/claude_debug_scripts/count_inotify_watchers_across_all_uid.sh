# Total watches across all users
sudo find /proc/*/fdinfo/* -exec grep -l inotify {} \; 2>/dev/null | xargs wc -l | tail -1