#!/bin/bash
#
# rclone upload script with optional Discord notification upon move completion (if something is moved)
# Credit to @XantherBanter - Github
#
# -----------------------------------------------------------------------------
LOCK_FILE="/run/rclone-$JOB.lock"
LOG_FILE="/var/log/rclone/$JOB.log"
# -----------------------------------------------------------------------------
trap 'rm -f $LOCK_FILE; exit 0' SIGINT SIGTERM
if [ -e "$LOCK_FILE" ]; then
  echo "$JOB is already running."
  exit
elif [ -z "$SKIP_IGNORE" ] && (rclone lsd "$SOURCE_DIR".ignore 2> /dev/null || rclone lsd "$DESTINATION_DIR".ignore 2> /dev/null) ; then
  echo "$JOB skipped due to .ignore folder"
  fail_data='{
    "username": "'"$JOB - rclone"'",
    "content": "skipped due to .ignore folder"
  }'
  /usr/bin/curl -H "Content-Type: application/json" -d "$fail_data" "$DISCORD_WEBHOOK_URL"
  exit
else
  touch "$LOCK_FILE"
  rclone_move() {
    rclone_command=$(
      /usr/bin/rclone sync -P \
        --config=/etc/rclone-sync/rclone.conf \
        --copy-links \
        --drive-stop-on-upload-limit \
        --drive-stop-on-download-limit \
        --fast-list \
        --log-file="$LOG_FILE" \
        --log-level=INFO \
        --progress \
        --stats=9999m \
        --track-renames \
        "$ADDL_FLAGS" \
        "$SOURCE_DIR" "$DESTINATION_DIR" 2>&1
    )
    # "--stats=9999m" mitigates early stats output
    # "2>&1" ensures error output when running via command line
    echo "$rclone_command"
  }
  rclone_move
  if [ "$DISCORD_WEBHOOK_URL" != "" ]; then
    rclone_sani_command="$(echo $rclone_command | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')" # Remove all escape sequences
    # Notifications assume following rclone ouput:
    # Transferred: 0 / 0 Bytes, -, 0 Bytes/s, ETA - Errors: 0 Checks: 0 / 0, - Transferred: 0 / 0, - Elapsed time: 0.0s
    transferred_amount=${rclone_sani_command#*Transferred: }
    transferred_amount=${transferred_amount%% /*}
    send_notification() {
      output_transferred_main=${rclone_sani_command#*Transferred: }
      output_transferred_main=${output_transferred_main% Errors*}
      output_errors=${rclone_sani_command#*Errors: }
      output_errors=${output_errors% Checks*}
      output_checks=${rclone_sani_command#*Checks: }
      output_checks=${output_checks% Transferred*}
      output_transferred=${rclone_sani_command##*Transferred: }
      output_transferred=${output_transferred% Elapsed*}
      output_elapsed=${rclone_sani_command##*Elapsed time: }
      notification_data='{
        "username": "'"$JOB - rclone"'",
        "avatar_url": "'"$DISCORD_ICON"'",
        "content": null,
        "embeds": [
          {
            "title": "Rclone Sync Task: Success!",
            "color": 4094126,
            "fields": [
              {
                "name": "Transferred",
                "value": "'"$output_transferred_main"'"
              },
              {
                "name": "Errors",
                "value": "'"$output_errors"'"
              },
              {
                "name": "Checks",
                "value": "'"$output_checks"'"
              },
              {
                "name": "Transferred",
                "value": "'"$output_transferred"'"
              },
              {
                "name": "Elapsed time",
                "value": "'"$output_elapsed"'"
              }
            ],
            "thumbnail": {
              "url": null
            }
          }
        ]
      }'
      /usr/bin/curl -H "Content-Type: application/json" -d "$notification_data" $DISCORD_WEBHOOK_URL
    }
    if [ "$transferred_amount" != "0" ]; then
      send_notification
    fi
  fi
  rm -f "$LOCK_FILE"
  trap - SIGINT SIGTERM
  exit
fi