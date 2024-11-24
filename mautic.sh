#!/bin/bash

LOGGING=1
PHP_PATH="/opt/plesk/php/8.2/bin/php"
MAUTIC_CONSOLE_PATH="httpdocs/bin/console"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SCRIPT_NAME="$(basename "$0")"
UNIQUE_SCRIPT_NAME="$(echo "$SCRIPT_DIR/$SCRIPT_NAME" | md5sum | cut -d' ' -f1)"
LOCKFILE="/tmp/${UNIQUE_SCRIPT_NAME}.lock"
LOG_FILE="$SCRIPT_DIR/logs/mautic_log"
COMMANDS=(
    "mautic:segments:update --batch-limit=100"
    "mautic:campaigns:update --batch-limit=100"
    "mautic:campaigns:trigger --batch-limit=100"
    "messenger:consume email --time-limit=50"
    # "mautic:import --limit=100"
    # "mautic:webhooks:process"
    # "mautic:reports:scheduler"
)

log_message() {
    if [[ $LOGGING -eq 1 ]]
    then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SCRIPT_NAME: $1" >> "$LOG_FILE"
    fi
}

run_command() {
    local COMMAND="$1"
    local START_TIME=$(date +%s)
    log_message "Starting $COMMAND"
    
    if $PHP_PATH $MAUTIC_CONSOLE_PATH $COMMAND --no-interaction --no-ansi; then
        local END_TIME=$(date +%s)
        log_message "Completed $COMMAND in $((END_TIME - START_TIME)) seconds"
    else
        log_message "Error: $COMMAND failed"
        cleanup
    fi
}

cleanup() {
    rm -f "$LOCKFILE"
    exit 1
}

trap 'cleanup' INT TERM ERR

if [ -e "$LOCKFILE" ]; then
    echo "Previous instance of $SCRIPT_NAME is still running."
    exit 1
fi

touch "$LOCKFILE"

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
log_message "Script started at: $START_TIME"
TOTAL_START=$(date +%s)

for COMMAND in "${COMMANDS[@]}"; do
    run_command "$COMMAND"
done

TOTAL_END=$(date +%s)
TOTAL_TIME=$((TOTAL_END-TOTAL_START))
log_message "Finished within $TOTAL_TIME seconds"

rm -f "$LOCKFILE"
exit 0