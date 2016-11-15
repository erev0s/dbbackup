# dbbackup script
#erev0s 2016/11

This script is made in an effort to automate the procedure of backing up databases.
You can use your pushover account with it and your email account to receive notifications that the backup went well
I have included a check on mysqldump so you would know if the process ended with an error.


    it creates the path to store the databases
    it deletes files in this path that are older than 5 days
    it echoes all databases
    it skips schema databases and all databases with underscore
    it backups up databases and notifies if any database dump ends with error
    it emails the results to you, and send them through pushover too


##################################
###########-to do list-###########
##################################
move the delete till after verifying that the backup went well
add a list of databases to be ignored
