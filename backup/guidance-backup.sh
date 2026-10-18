#!/bin/bash
# Guidance (Ubuntu / PlinkCom) backup. Run as root.
BLACKBOX="plinktern@172.16.21.5"
DIR="/home/plinktern/backups/guidance"
TS=$(date +%Y%m%d_%H%M%S)
ARCHIVE="/root/guidance_${TS}.tar.gz"

tar -czf "$ARCHIVE" /etc /var /home /opt /srv /var/www
ssh "$BLACKBOX" "mkdir -p $DIR"
scp "$ARCHIVE" "$BLACKBOX:$DIR/"
