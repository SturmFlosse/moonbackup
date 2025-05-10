# This list contains known shell commands to get information about jobs in TrueNAS or run those jobs
# Hint: Every job has its own JSON-file that can be viewed

# See details on all replication jobs of your system
midclt call replication.query | jq 

# See only the replication id, name and state
midclt call replication.query | jq '.[] | {id, name}'
midclt call replication.query | jq '.[] | {id, name, state}'

# Run a replication task
midclt call replication.run <JOB_ID>

# See the cronjob id and description 
midclt call cronjob.query | jq 
midclt call cronjob.query | jq '.[] | {id, description}'

# Run a cronjob
midclt call cronjob.run <JOB_ID>

# Shutdown TrueNAS - now
midclt call system.shutdown

# Shutdown TrueNAS - in 10 min
sleep 600 && midclt call system.shutdown

# Reboot a TrueNAS system - now
midclt call system.reboot

# Call a script from the TrueNAS Shell
/mnt/pool/dataset/folder/script.sh
