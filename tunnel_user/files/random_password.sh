#!/bin/bash
if [ "$#" -eq 1 ]
then
    user="$1"
else
    user=tunnel
fi

echo Setting a random password to "$user"
printf "$(pwgen -s 32 1)\n%.0s" {1..2} | passwd "$user" &>/dev/null
