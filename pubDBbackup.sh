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


#if your db starts with an _ then ignore it this way you can create dbs with _ if you want them ignored
#need to add a list of databases so you can add a database you need to be ignored
for db in $DBS; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "performance_schema" ]] ; then
        echo "Dumping database: $db"
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
		echo "$db ERROR BACKING UP === errorcode = $exitcode" >> $STATUS
		
		else
		echo "$db Backed up with EXITCODE [ $exitcode ] and with size $FILESIZE bytes" >> $STATUS
		fi
		
	fi
done


#method to remove old database backups
find $DELPATH* -mtime +5 -exec rm {} \;



#notify me of all the results
        curl -s \
        -F "token=$TOKEN" \
        -F "user=$USERID" \
        -F "message=$(cat $STATUS)" \
        -F "priority=0"\
        https://api.pushover.net/1/messages.json
		
#by mail too
echo "$(cat $STATUS)" | mail -s "Database Backup Results" $MAIL	






