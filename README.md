# f5-backup.sh
## Overview

Another Bash script to backup a BIG-IP device.
## How it Works

The backup script is executed from the BIG-IP device and the UCS file created is copied to a remote SCP server. All the backup steps are logged to the local syslog.

## How to Use

1. Create a directory on BIG-IP to host the backup script and the ssh key pair:
    ```
    mkdir /shared/scripts/f5-backup/
    ```
2. Copy the script *f5-backup.sh* to the BIG-IP and put it on the directory previously created ; 

3. Give execute permission to the script:
    ```
    chmod +x f5-backup.sh
    ```
3. Generate a SSH key pair which will be used by the script to copy the UCS file to the remote SCP server:
    ```
    cd /shared/scripts/f5-backup/
    mkdir mykeys
    ssh-keygen -f mykeys/f5user
    ```
4. Copy the public key (*f5user.pub*, in this case) to the SCP server and put it in the file ".ssh/authorized_keys" inside the user's home directory ;

5. Adjust the following settings inside the script file accordingly with your environment:
    ```
    SCPHOST="172.16.150.1"
    SCPUSER="f5user"
    SCPKEY="/shared/scripts/f5-backup/mykeys/f5user"
    SCPREMOTEDIR="/home/f5user/"
    ```
6. To encrypt the UCS file configure the *PASSPHRASE* variable inside the script (if left blank the UCS will be not encrypted);

7. Test the script (using *DEBUG=1*, inside the script) ;
    ```
    ./f5-backup.sh
    ```
    
    **Note:** If trying to create an encrypted UCS file, use the root user to execute the script (https://cdn.f5.com/product/bugtracker/ID791365.html).

8. Create an *iCall* script which will execute the *f5-backup.sh* script:
    ```
    tmsh create sys icall script backup
    tmsh modify sys icall script backup definition { exec /shared/scripts/f5-backup/f5-backup.sh }
    ```
9. Create an *iCall* periodic handler which will execute the iCall script created previously (adjust the "interval" setting accordingly to your needs):
    ```
    tmsh create sys icall handler periodic backup first-occurrence 2022-02-02:00:00:00 interval 86400 script backup
    ```
10. Save the configuration: 
    ```
    tmsh save sys config
    ```
    
## Sample output
```
    # ./f5-backup.sh 
    Feb  7 09:59:12 bigip1.f5lab.local info admin[3811]: [backup-task][ID=20220207095912] => Starting the backup.
    Feb  7 09:59:12 bigip1.f5lab.local info admin[3812]: [backup-task][ID=20220207095912] => Running the UCS save operation (encrypted).
    Feb  7 09:59:30 bigip1.f5lab.local info admin[5558]: [backup-task][ID=20220207095912] => UCS file saved successfully (local:/var/local/ucs/bigip1-20220207-095912.ucs).
    Feb  7 09:59:30 bigip1.f5lab.local info admin[5570]: [backup-task][ID=20220207095912] => Running the UCS SCP copy operation.
    Feb  7 09:59:31 bigip1.f5lab.local info admin[5576]: [backup-task][ID=20220207095912] => UCS file copied to the SCP server successfully (remote:172.16.150.1:/home/f5user//bigip1-20220207-095912.ucs).
    Feb  7 09:59:31 bigip1.f5lab.local info admin[5577]: [backup-task][ID=20220207095912] => Running the UCS delete operation.
    Feb  7 09:59:31 bigip1.f5lab.local info admin[5585]: [backup-task][ID=20220207095912] => UCS file deleted successfully (local:/var/local/ucs/bigip1-20220207-095912.ucs).
    Feb  7 09:59:31 bigip1.f5lab.local info admin[5586]: [backup-task][ID=20220207095912] => Backup succeeded.
```  
