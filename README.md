# moonbackup
In this repository you will find scripts and guides to fully automate TrueNAS replication systems. 

# Diclaimer
Take a close look at the scripts for yourself and really try to understand how they work and how to use them. These scripts were created for a special use case and should be treated this way. I will not take responsibility for any damage or loss of data that may occur on your systems! 

I am not a professional programmer and never will be but I wanted this solution so I did a lot of research and got these scripts working. Also I don't have much experience using Github but I read online that many other people are searching for the same solutions. So I thought it might help others as well. 

If you see improvements, please let me and others know and maybe we can implement your changes in the scripts. Otherwise you can fork this repository and create your own scripts. 

If you find the scripts and guidelines helpful and you feel the need to thank me, please don't. I am not doing this for money. I just wanna contribute to a great community and maybe lower the power consumption of NAS systems for everyone a bit. 
If you feel the need, donate some of your energy savings to your local animal shelter or something else. Thanks :)

# Use Case

A main TrueNAS system is running 24/7 while a second TrueNAS system only powers on at night (or any other specific time), runs pull replication jobs to receive the latest snapshots of the main system and then powers off again. 

Why?
- Avoidance of unnecessary energy consumption
- Avoidance of unnecessary burden on the backup drive(s)
- Automated (remote) replications for disaster recoveries

# How it works

Explanation of the basics: 
1. Every Cron and Replication Job has its own json-file in the backend of TrueNAS. This contains information about the task such as id, name, description, state,... When you configure a task using the WebUI you are basically defining the entries in the json file. Using shell commands we can retrieve data from those json files and implement these into custom scripts.
2. Every Cron and Replication Job can be run as a shell command.

You can find a list of commands in this repository.

Automation - step by step:
1. System gets powered on
2. A cron job is scheduled to run every XX min: It runs the script "run_replication_check_use_lockfile.sh" (runs every replication job one after another, then calls another cron job)
3. The called cron job runs the script "scrub-replication-check-shutdown-5min_lockfile.sh" which checks regularly if any tasks are running. If no, it activates another cron job and then waits XX min before shutting down the system
4. In the XX minute wait time the third cron job and script "Replication_LOG.sh" fetches the "last succeeded" state and time of every replication job, lists them and sends an e-mail to the admin
5. The system gets powered off by the command from the second script after the wait time

A fourth cron job with the script "scrub-replication-check-System-still-online.sh" can be configured to send a mail the admin if the system is still powered on. Just set the cron job schedule to the appropriate time you want to get informed. 

These scripts do not depend on any additional plugins or features. They just use shell commands native to TrueNAS Scale.

This also works with replication tasks to a remote location - e.g. with Tailscale.

# What you will need

On the main TrueNAS system:
- Snapshots to replicate from the main TrueNAS system

On the second TrueNAS system:
- A BIOS that can be enabled to power on a system either with "RTC Wake up (Power on on time)" or after receiving power from the wall ("After Power loss")
- Access to the BIOS
- Access to the WebGUI and admin rights
- Configured Replication Tasks with a PULL configuration
- A configured mail service in the TrueNAS WebUI (see below)
- A dataset or folder to store the scripts

Optionally: A smart power outlet to make it easier to switch on the second system, to check if the system is really powered off and to power the second system on outside of the schedule (alternative to Wake on LAN).
A smart power outlet is recommended because BIOS often refers to UTC Timezone and may differ from the time you want to wake up your system. Also an option to wake up the system automatically is a nice to have.

Mail service: 
To receive an e-mail from your TrueNAS system you need to configure the mail-service. You can do this by going to System Setting - General and configure mail at the bottom. Then go to System Settings - Alert Settings and configure an sender mail and receiving mail address. 
After you confirmed that a test mail can reach your inbox, configure the cron jobs calling the "Replication_LOG.sh" and "scrub-replication-check-System-still-online.sh" by unchecking "Hide Standard Output". Unchecking this will send you an e-mail of the output of the cron job. 


# How to achieve this

1. Choose between one of the following options to automatically power on the system
  - No smart power outlet: Go into the BIOS and set "RTC Wake up" to the time the system should power on automatically (BIOS often refers to UTC, better to test yours yourself)
  - With a smart power outlet: Set the BIOS to "What to do after Power Loss?" to "Turn on". Then choose a time in the app of the smart power outlet to turn the smart power outlet on automatically
2. Turn on the second system
3. Place the scripts from the "scripts"-folder of this repository into a dataset or folder on the system
4. Go to System Settings - Advanced - scroll down to Cron Jobs
5. Add the following cron tasks:
  1. Description: "Run Replication Check Use Lockfile", command: "/mnt/pool/dataset/folder/run_replication_check_use_lockfile.sh", Run as user: someadminuser, Schedule: Every XX min (e.g. 15), Check "Hide Standard Output", Uncheck "Hide Standard Error", Uncheck "Enabled" (we will turn this on later).
  2. Description: "Check Replication Scrub, Mail, Shutdown", command: "/mnt/pool/dataset/folder/scrub-replication-check-shutdown-5min_lockfile.sh", Run as user: someadminuser, Schedule: Default, Check "Hide Standard Output", Uncheck "Hide Standard Error", Uncheck "Enabled"
  3. Description: "Replication LOG Mail", command: "/mnt/pool/dataset/folder/Replication_LOG.sh", Run as user: someadminuser, Schedule: Default, Uncheck "Hide Standard Output", Uncheck "Hide Standard Error", Uncheck "Enabled"
  4. Description: "System still online", command: "/mnt/pool/dataset/folder/scrub-replication-check-System-still-online.sh", Run as user: someadminuser, Schedule: Timeframe you want to get notified, Uncheck "Hide Standard Output", Uncheck "Hide Standard Error", Check "Enabled"
6. Go to the Truenas Shell (System Settings - Shell) and run the command " midclt call cronjob.query | jq '.[] | {id, description}' " to see each cron job id with its description. Note them down (or screenshot).
7. Open the script "run_replication_check_use_lockfile.sh" with your prefered editor of choice and add the cron job id with the description "Check Replication Scrub, Mail, Shutdown" at the end of the script. Save the changes
8. Open the script "scrub-replication-check-shutdown-5min_lockfile.sh" with your prefered editor of choice and add the cron job id with the description "Replication LOG Mail" roughly in the middle of the script. Save the changes
9. Test run: In the TrueNAS WebUI go to System Settings - Advanced - Cron Jobs. There you can either open the cron job with the description "Run Replication Check Use Lockfile", check "Enabled" and wait till the cron gets activated by time or run it manually.

The replications should start, after that a mail should get sent to your mail account with a summary of your replications and then the system should shutdown automatically. 
If you did run the cron job manually without enabling it, it will not run automatically via schedule (= not running replications and shutdown the system). To run everything automatically you need to check "Enabled" in the cron job. 


# Known issues and improvements

- Instead of calling other cron jobs in the scripts, call the script directly (not suitable for mail notifications)

- When the system gets powered on manually, scripts run automatically and shutdown the system before the admin can configure something.
  - Solution: Picking a time for powering on the system right after the cron schedule. Then disabling the cron job "Run Replication Check Use Lockfile" right after logging into the WebUI. Enabling it before shutting down againg to start the automation next time the system gets powered on.
















