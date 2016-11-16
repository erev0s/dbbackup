#!/bin/bash
datenow=`date +"%Y%m%d"`;
USER=""
PASSWORD=""
path="/root/dbs/$datenow"
DELPATH="/root/dbs/"
STATUS="/root/dbs/statusfile.$datenow"
TOKEN=""
USERID=""
MAIL=""


# if the directory does not exist, make it please
if [ ! -d $path ]; then
  mkdir -p $path
else
 :
fi


DBS="$(mysql -u$USER -p$PASSWORD -Bse 'show databases')"
echo "$DBS"

errorcounter=0 #innitializing a variable to count errors in mysqldump

#if your db starts with an _ then ignore it this way you can create dbs with _ if you want them ignored
#need to add a list of databases so you can add a database you need to be ignored
for db in $DBS; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "performance_schema" ]] ; then
        printf "Dumping database: $db\n"
		        mysqldump --force --opt --user=$USER --password=$PASSWORD --databases $db > $path/`date +%Y%m%d`.$db.sql
				exitcode=$?
        gzip $path/`date +%Y%m%d`.$db.sql
		FILESIZE=$(stat -c%s "$path/`date +%Y%m%d`.$db.sql.gz")
		printf "$db Backed up with EXITCODE [ $exitcode ] and with size $FILESIZE bytes\n";
		
		#create an if to notify us in case of bad mysqldump
		if [ $exitcode -ne 0 ]; then
		curl -s \
		-F "token=$TOKEN" \
        -F "user=$USERID" \
        -F "message=$db ERROR BACKING UP === errorcode = $exitcode   " \
        -F "priority=1"\
        https://api.pushover.net/1/messages.json	
		printf "\n\n$db ERROR BACKING UP === errorcode = $exitcode \n\n" >> $STATUS
		((errorcounter++))
		else
		printf "\n$db Backed up with EXITCODE [ $exitcode ] and with size $FILESIZE bytes\n" >> $STATUS
		fi
		
	fi
done


#method to remove old database backups
if [ $errorcounter -ne 0 ]; then
	printf "Not deleting anything due to errors in mysqldump\n" >> $STATUS
else
	find $DELPATH* -mtime +5 -exec rm {} \;
	printf "\nFiles older than 5 days have been deleted\n" >> $STATUS
fi

#notify me of all the results
        curl -s \
        -F "token=$TOKEN" \
        -F "user=$USERID" \
        -F "message=server is $(hostname) $(cat $STATUS)" \
        -F "priority=0"\
        https://api.pushover.net/1/messages.json
		
#by mail too
printf "Server hostname is $(hostname)\n$(cat $STATUS)" | mail -s "Database Backup Results" $MAIL