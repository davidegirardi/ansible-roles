#!/bin/bash
if [ "$#" -eq 1 ]
then
    user="$1"
else
    user=tunnel
fi

echo Setting the following password to "$user"
printf "$(pwgen 10 1)\n%.0s" {1..2} | tee >(passwd "$user" &>/dev/null) | tail -n 1

echo Waiting for the user "$user" to login...
journalctl -f -n0 -u ssh.service | grep -q "user $user"

echo "Running processes for $user"
echo Status:
ps -U"$user"

echo
echo Setting a random password to "$user"
printf "$(pwgen -s 32 1)\n%.0s" {1..2} | passwd "$user" &>/dev/null


