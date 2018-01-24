#!/bin/bash

# ansible prerequisites for ubuntu

[ $(id -u) -ne 0 ] && echo "Must be run as 'root' user." && exit 1

PACKAGES=(
    apt-utils
    openssh-server
    python
)

apt-get install -y "${PACKAGES[@]}"
apt-get update && apt-get -y dist-upgrade

SELF=$(who am i|cut -f1 -d" ")
SUDOERS_LINE="$SELF ALL=(ALL) NOPASSWD:ALL"
grep -q "$SUDOERS_LINE" /etc/sudoers || echo "$SUDOERS_LINE" >> /etc/sudoers