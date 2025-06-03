    #!/bin/bash

LOCKFILE="/tmp/replication.lock"

# Check if the lock file exists (meaning another instance is running)
if [[ -f "$LOCKFILE" ]]; then
    echo "Replication-Script is already running. Exiting to prevent duplicate execution."
    exit 1
fi

LOCKFILE2="/tmp/replication_scrub_check.lock"

# Check if the lock file exists (meaning another instance is running)
if [[ -f "$LOCKFILE2" ]]; then
    echo "Shutdown-Script is already running. Exiting to prevent duplicate execution."
    exit 1
fi

# Create the lock file to indicate this script is running
touch "$LOCKFILE"

# Get today's date in YYYY-MM-DD format
today=$(date +'%Y-%m-%d')

# Step 1: Get replication jobs that are NOT finished today and have a valid ID
replications=$(midclt call replication.query | jq -c --arg today "$today" '
    .[] | select(.id and .state.state != "FINISHED" or (.state.datetime["$date"] / 1000 | strftime("%Y-%m-%d") != $today)) | 
    {id: .id, name: .name} 
')

# Step 2: Loop through each replication job and run it
while IFS= read -r replication; do
    id=$(echo "$replication" | jq -r '.id')

    # Ensure the job has a valid ID before running
    if [[ -z "$id" || "$id" == "null" ]]; then
        echo "Skipping a replication job with an invalid ID."
        continue
    fi

    name=$(echo "$replication" | jq -r '.name')

    echo "Running replication job: $name (ID: $id)"
    midclt call replication.run "$id"
    
    if [ $? -ne 0 ]; then
        echo "Error running replication job $name (ID: $id). Skipping..."
        continue
    fi

    # Wait for the replication job to finish
    echo "Waiting for replication job $name (ID: $id) to finish..."
    while :; do
        state=$(midclt call replication.query | jq -r --arg id "$id" '
            .[] | select(.id == ($id | tonumber)) | .state.state')

        if [[ "$state" == "FINISHED" ]]; then
            echo "Replication job $name (ID: $id) completed successfully."
            break
        fi

        echo "Replication job $name (ID: $id) is still running..."
        sleep 120  # Check every 2 minutes
    done

    # Sleep for 60 seconds before processing the next job
    echo "Waiting 1 minute before running the next replication job..."
    sleep 60

done <<< "$replications"

# Remove the lock file when the script completes
rm -f "$LOCKFILE"

echo "All applicable replication jobs processed."

midclt call cronjob.run <INSERT_JOB_ID>
