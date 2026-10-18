#!/bin/bash
# Ignition (Fedora / OpenWeb UI) backup. Run as root.
BLACKBOX="plinktern@172.16.21.5"
DIR="/home/plinktern/backups/ignition"
TS=$(date +%Y%m%d_%H%M%S)
ARCHIVE="/root/ignition_${TS}.tar.gz"

tar -czf "$ARCHIVE" /etc /var /home /opt /srv
ssh "$BLACKBOX" "mkdir -p $DIR"
scp "$ARCHIVE" "$BLACKBOX:$DIR/"
