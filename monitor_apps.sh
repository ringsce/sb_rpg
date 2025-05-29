#!/bin/bash

# Define the applications to monitor
APPS=("Qt_Creator" "Visual_Studio_Code")

# Define the log file
LOGFILE="$HOME/app_open_times.txt"

# Function to log the time when an app is opened
log_app_open() {
    local app_name=$1
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$app_name opened at: $timestamp" >> "$LOGFILE"
}

# Function to calculate elapsed time
calculate_elapsed_time() {
    local start_time=$1
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))
    local hours=$((elapsed_time / 3600))
    local minutes=$(( (elapsed_time % 3600) / 60 ))
    echo "$hours hours $minutes minutes"
}

# Initialize arrays to store start times
APP_START_TIMES=()

# Monitor the applications
while true; do
    for i in "${!APPS[@]}"; do
        app=${APPS[$i]}
        app_name_with_spaces=${app//_/ }  # Replace underscores with spaces for display
        if pgrep -x "$app_name_with_spaces" > /dev/null; then
            if [[ -z "${APP_START_TIMES[$i]}" ]]; then
                # App is running and start time is not set
                APP_START_TIMES[$i]=$(date +%s)
                log_app_open "$app_name_with_spaces"
            else
                # App is still running, update the elapsed time
                start_time=${APP_START_TIMES[$i]}
                elapsed_time=$(calculate_elapsed_time "$start_time")
                sed -i "" "/$app_name_with_spaces opened at:/s/\($app_name_with_spaces opened at:.*\)/\1 - Elapsed: $elapsed_time/" "$LOGFILE"
            fi
        else
            # App is not running, clear the start time and remove the elapsed time from the log
            if [[ -n "${APP_START_TIMES[$i]}" ]]; then
                unset APP_START_TIMES[$i]
                sed -i "" "/$app_name_with_spaces opened at:/s/\($app_name_with_spaces opened at:.*\) - Elapsed:.*/\1/" "$LOGFILE"
            fi
        fi
    done
    sleep 1
done
