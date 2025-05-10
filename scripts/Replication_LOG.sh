#!/bin/bash

# Script to list the last run of every replication job on TrueNAS SCALE
# Automatically adjusts for DST based on date (Europe/Berlin style)

# Default: GMT+1 (Wintertime)
TIME_OFFSET_SECONDS=3600

# Get today's date in YYYYMMDD format
today=$(date +%m%d)

# Define ranges for summer time (last Sunday in March to last Sunday in October)
# We'll use approximate range: 03-31 to 10-31
if [[ "$today" > "0330" && "$today" < "1031" ]]; then
    # Summer time: GMT+2
    TIME_OFFSET_SECONDS=7200
fi

echo "Fetching replication task status..."

# Get replication task state using midclt
replication_tasks=$(midclt call replication.query)


echo -e "\n-----------------------------------------------------------------------------------------------------------"

# Print header
echo -e "\nLast run of the replication tasks ($(($TIME_OFFSET_SECONDS / 3600)) hours before UTC):\n"

echo "$replication_tasks" | jq -r --argjson offset "$TIME_OFFSET_SECONDS" '
  .[] |
  {
    name: .name,
    timestamp_ms: .state["datetime"]["$date"]
  } |
  "\(.name)\t\(
    if .timestamp_ms != null 
    then ( ((.timestamp_ms / 1000) + $offset) | strftime("   //   %Y-%m-%d   //   %H:%M") )
    else "Nie"
    end
  )"
' | column -t

echo -e "\n-----------------------------------------------------------------------------------------------------------"

echo -e "\n$(date +"%Y-%m-%d - %H:%M"): \n\nNo replication or scrub tasks running. \n\nProceeding with shutdown..."
