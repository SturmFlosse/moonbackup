# moonbackup
In this repository you will find scripts and guides to fully automate TrueNAS replication systems. 

# Diclaimer
Take a close look at the scripts for yourself and really try to understand how they work and how to use them. These scripts were created for a special use case and should be treated this way.

I am not a professional programmer and never will be but I wanted this solution so I did a lot of research and got these scripts working. Also I don't have much experience using Github but I read online that many other people are searching for the same solutions. So I thought it might help others as well. 

If you see improvements, please let me and others know and maybe we can implement your changes in the scripts. Otherwise you can fork this repository and create your own scripts. 

If you find the scripts and guidelines helpful and you feel the need to thank me, please don't. I am not doing this for money or something else. If you feel the need, donate some money to your local animal shelter or something else. Thanks :)

# Use Case

A main TrueNAS system is running 24/7 while a second TrueNAS system only powers on at night (or any other specific time), runs pull replication jobs to receive the latest snapshots of the main system and then powers off again. 

## Why?

- Avoidance of unnecessary energy consumption
- Avoidance of unnecessary burden on the backup drive(s)
- Automated (remote) replications for disaster recoveries

# What you will need

- Snapshots to replicate from the main TrueNAS system
- Access to the BIOS of the second TrueNAS system
- Access to the WebGUI and admin rights on the second TrueNAS system
- The  


Optionally: A smart power outlet to make it easier to switch on the second system, to check if the system is really powered off and to turn the second system on outside of the schedule (alternative to Wake on LAN).

# How it works
