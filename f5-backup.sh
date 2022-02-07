#!/bin/bash

CTIME=$(date +"%Y%m%d-%H%M%S")
TASKID=$(date +"%Y%m%d%H%M%S")
HOSTNAME=$(uname -n | cut -d "." -f 1)
FILENAME="$HOSTNAME-$CTIME.ucs"
PASSPHRASE=""
DEBUG=1

SCPHOST="172.16.150.1"
SCPUSER="f5user"
SCPKEY="/shared/scripts/f5-backup/mykeys/f5user"
SCPREMOTEDIR="/home/f5user/"

function debug () {
   if test $DEBUG -eq 1
   then
      grep "\[backup-task\]\[ID=$TASKID\]" /var/log/ltm
   fi
}

function save_ucs () {

   if [ -n "$PASSPHRASE" ];
   then
      logger -p local0.info "[backup-task][ID=$TASKID] => Running the UCS save operation (encrypted)."
      tmsh save /sys ucs $FILENAME passphrase "$PASSPHRASE" > /dev/null 2>&1 
   else
      logger -p local0.info "[backup-task][ID=$TASKID] => Running the UCS save operation (not encrypted)."
      tmsh save /sys ucs $FILENAME > /dev/null 2>&1
   fi

   if test $? -eq 0
   then
      logger -p local0.info "[backup-task][ID=$TASKID] => UCS file saved successfully (local:/var/local/ucs/$FILENAME)."
   else
      logger -p local0.error "[backup-task][ID=$TASKID] => UCS save operation failed."
      return 1
   fi

   return 0

}

function scpcopy_ucs () {

   logger -p local0.info "[backup-task][ID=$TASKID] => Running the UCS SCP copy operation."

   scp -i $SCPKEY /var/local/ucs/$FILENAME $SCPUSER@$SCPHOST:$SCPREMOTEDIR/ > /dev/null 2>&1

   if test $? -eq 0
   then
      logger -p local0.info "[backup-task][ID=$TASKID] => UCS file copied to the SCP server successfully (remote:$SCPHOST:$SCPREMOTEDIR/$FILENAME)."
   else
      logger -p local0.error "[backup-task][ID=$TASKID] => UCS SCP copy operation failed."
      return 1
   fi

   return 0

}

function delete_ucs () {

   logger -p local0.info "[backup-task][ID=$TASKID] => Running the UCS delete operation."
 
   tmsh delete /sys ucs $FILENAME > /dev/null 2>&1

   if test $? -eq 0
   then
      logger -p local0.info "[backup-task][ID=$TASKID] => UCS file deleted successfully (local:/var/local/ucs/$FILENAME)."
   else
      logger -p local0.error "[backup-task][ID=$TASKID] => UCS delete operation failed."
      return 1
   fi
  
   return 0

}

function backup () {

   logger -p local0.info "[backup-task][ID=$TASKID] => Starting the backup."

   save_ucs
   save_ucs_status=$?

   if test $save_ucs_status -eq 0
   then
      scpcopy_ucs
      scpcopy_ucs_status=$?

      delete_ucs
      delete_ucs_status=$?
   fi

   if [ "$save_ucs_status" -eq 1 ] || [ "$scpcopy_ucs_status" -eq 1 ] || [ "$delete_ucs_status" -eq 1 ]
   then
      logger -p local0.info "[backup-task][ID=$TASKID] => Backup failed."
      status=1
   else
      logger -p local0.info "[backup-task][ID=$TASKID] => Backup succeeded."
      status=0
   fi

   debug
   
   exit $status  

}

backup
