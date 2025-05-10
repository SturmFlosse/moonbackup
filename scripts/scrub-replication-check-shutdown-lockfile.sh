#!/bin/bash

LOCKFILE="/tmp/replication_scrub_check.lock"

# Check if the lock file exists (meaning another instance is running)
if [[ -f "$LOCKFILE" ]]; then
    echo "Script is already running. Exiting to prevent duplicate execution."
    exit 1
fi

# Create the lock file to indicate this script is running
touch "$LOCKFILE"

# How often to check (in seconds)
INTERVAL=300     # 5 minutes

# Function to check if any replication tasks are still running
are_replications_finished() {
    local unfinished_count
    unfinished_count=$(midclt call replication.query | jq '[.[] | select(.state.state != "FINISHED")] | length')

    echo "$(date): Debug - Unfinished replication tasks count: $unfinished_count"
    [[ "$unfinished_count" -eq 0 ]]
    return $?
}

# Function to check if any scrub is currently running
is_scrub_running() {
    local scanning_pools
    scanning_pools=$(midclt call pool.query | jq '[.[] | select(.scan.state == "SCANNING")] | length')

    echo "$(date): Debug - Pools currently being scrubbed: $scanning_pools"
    [[ "$scanning_pools" -eq 0 ]] && return 1 || return 0
}

echo "Monitoring replication and scrub tasks..."

# Loop while replication or scrub tasks are running
while true; do
    if are_replications_finished && ! is_scrub_running; then
        break
    fi
    echo "$(date): Replication or scrub tasks still running. Waiting 5 minutes..."
    sleep "$INTERVAL"
done

midclt call cronjob.run <INSERT_JOB_ID>

echo "$(date): All tasks are finished. Waiting an additional 5 minutes before shutdown..."
sleep "$INTERVAL"

# Double-check before shutdown
if are_replications_finished && ! is_scrub_running; then
    echo "$(date): No replication or scrub tasks running. Proceeding with shutdown..."

# Remove the lock file when the script completes
rm -f "$LOCKFILE"

    midclt call system.shutdown
else
    echo "$(date): A task restarted. Resuming monitoring loop..."
    exec "$0"
fi


