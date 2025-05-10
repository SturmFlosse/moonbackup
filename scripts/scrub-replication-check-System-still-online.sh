#!/bin/bash

LOCKFILE="/tmp/replication_scrub_check.lock"

# Check if the lock file exists (meaning another instance is running)
if [[ -f "$LOCKFILE" ]]; then
    echo "Script is already running. Exiting to prevent duplicate execution."
    exit 1
fi

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
        echo "$(date): All tasks are FINISHED BUT THE SYSTEM IS STILL ONLINE!"
        break
    fi
    echo "$(date): $unfinished_count replication tasks and $scanning_pools Scrub tasks still running."
    echo "$(date): Cron job will run again in one hour..."
done

