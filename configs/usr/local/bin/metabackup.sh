#!/bin/sh
# metaback.sh - backup script for metadata with rclone

REPO="/home/metabackup/repository"

cd $REPO || exit
for REMOTE in $(rclone listremotes)
do
    echo "Backing up $REMOTE"
    rclone lsjson \
        --cache-dir /etc/rclone-sync \
        --fast-list \
        --recursive "$REMOTE" > $REPO/"$REMOTE"-tmp.json
    jq -s '.[] | sort_by(.Name, .Path)' "$REMOTE"-tmp.json > "$REMOTE".json
    rm "$REMOTE"-tmp.json
done
git add --all
git commit -m "metabackup $(date -Iminutes)"
git push origin main