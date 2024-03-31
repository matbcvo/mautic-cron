#!/bin/bash

LOGGING=1
PHP_PATH="/opt/plesk/php/8.0/bin/php"
SCRIPT_NAME="mautic-name"
LOCKFILE="/tmp/${SCRIPT_NAME}.lock"

if [ -e "$LOCKFILE" ]; then
    echo "Previous instance of $SCRIPT_NAME is still running."
    exit 1
fi

touch "$LOCKFILE"

cleanup() {
    rm -f "$LOCKFILE"
    exit 1
}

trap 'cleanup' INT TERM ERR

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOG_FILE="$SCRIPT_DIR/logs/mautic_log"
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

log_message() {
    if [[ $LOGGING -eq 1 ]]
    then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SCRIPT_NAME: $1" >> $LOG_FILE
    fi
}

log_message "Script started at: $START_TIME"

TOTAL_START=$(date +%s)

START=$(date +%s)
$PHP_PATH httpdocs/bin/console mautic:broadcasts:send --limit=100 --no-interaction --no-ansi
END=$(date +%s)
log_message "Completed mautic:broadcasts:send within $((END-START)) seconds"

START=$(date +%s)
$PHP_PATH httpdocs/bin/console mautic:emails:send --message-limit=50 --no-interaction --no-ansi
END=$(date +%s)
log_message "Completed mautic:emails:send within $((END-START)) seconds"

START=$(date +%s)
$PHP_PATH httpdocs/bin/console mautic:segments:update --batch-limit=100 --no-interaction --no-ansi
END=$(date +%s)
log_message "Completed mautic:segments:update within $((END-START)) seconds"

START=$(date +%s)
$PHP_PATH httpdocs/bin/console mautic:campaigns:update --batch-limit=100 --no-interaction --no-ansi
END=$(date +%s)
log_message "Completed mautic:campaigns:update within $((END-START)) seconds"

START=$(date +%s)
$PHP_PATH httpdocs/bin/console mautic:campaigns:trigger --no-interaction --no-ansi
END=$(date +%s)
log_message "Completed mautic:campaigns:trigger within $((END-START)) seconds"

START=$(date +%s)
$PHP_PATH httpdocs/bin/console mautic:import --limit=500 --no-interaction --no-ansi
END=$(date +%s)
log_message "Completed mautic:import within $((END-START)) seconds"

# START=$(date +%s)
# $PHP_PATH httpdocs/bin/console mautic:webhooks:process --no-interaction --no-ansi
# END=$(date +%s)
# log_message "Completed mautic:webhooks:process within $((END-START)) seconds"

# START=$(date +%s)
# $PHP_PATH httpdocs/bin/console mautic:reports:scheduler --no-interaction --no-ansi
# END=$(date +%s)
# log_message "Completed mautic:reports:scheduler within $((END-START)) seconds"

TOTAL_END=$(date +%s)
TOTAL_TIME=$((TOTAL_END-TOTAL_START))
log_message "Finished within $TOTAL_TIME seconds"

rm -f "$LOCKFILE"