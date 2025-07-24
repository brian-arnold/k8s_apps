sudo find /proc/*/fd -lname anon_inode:inotify -exec ls -l {} \; 2>/dev/null | awk '{print $3}' | sort | uniq -c | sort -rn
