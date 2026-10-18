#!/bin/bash
# Restore Guidance (Ubuntu) system files from blackbox.
BLACKBOX="plinktern@172.16.21.5"
DIR="/home/plinktern/backups/guidance"

FILE=$(ssh "$BLACKBOX" "ls $DIR/*.tar.gz | tail -1" | xargs basename) #most recent
scp "$BLACKBOX:$DIR/$FILE" /root/
echo "Downloaded: /root/$FILE"
echo "Restore with: cd / && tar -xzvf /root/$FILE"
