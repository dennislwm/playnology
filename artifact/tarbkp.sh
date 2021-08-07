#!/usr/bin/env bash
#######Basic Information##########

FILE_NAME=mc.1.10.2-ftb-skyfactory.3.0.21
DATE=`date +%Y%m%d`
BACK_PATH=./data
#No. of backup copies
BACK_NUM=14

######Execute Function##########
back_up() {

  #backup file absolute path
  BACK_FILE=${DATE}.${FILE_NAME}.tar.gz

  #Execute the parameters of the mysqldump command
  SQL_OPT="-u${DB_USER}  -h ${DB_HOST} ${FILE_NAME}"

  #Execute backup
  tar cfvz $BACK_FILE $BACK_PATH

  #Delete files backed up 30 days ago
  #find ${BACK_PATH}/* -mtime +10 -exec rm {} \;
  
  #Write to create a backup log
  echo "create ${BACK_FILE}" >> $0.log

  #Find the backup that needs to be deleted
  delfile=`ls -l -crt *.${FILE_NAME}.tar.gz | awk '{ print $9 }'| head -1`

  #echo "${delfile}"
  #Judging whether the current number of backups is greater than $number
  count=`ls -l -crt *.${FILE_NAME}.tar.gz | awk '{ print $9 }'| wc -l`

  if [[ $count -gt $BACK_NUM ]]; then
    #Delete the oldest backup, only keep the number of backups
    rm $delfile

    #Write delete file log
    echo "delete $delfile" >> ${BACK_PATH}.log
  fi
}

back_up;
######End of file##########
