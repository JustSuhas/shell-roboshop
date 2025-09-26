#!/bin/bash
#!/bin/bash
R="\e[31m"
G="\e[32m"
O="\e[033m"
N="\e[0m"

USERID=$(id -u)

Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"

mkdir -p $Logs_Folder 

echo "Script started execution at: $(date)" | tee -a $Log_File

if [ $USERID -ne 0 ]; then
    echo -e "$R Error $N: Run this script with root privelege"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$R Error $N: $2 has failed" | tee -a $Log_File
        exit 1
    else
        echo -e "$2 ... $G successful $N" | tee -a $Log_File
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>>$Log_File
validate $? "Installing MongoDB"

systemctl enable mongodb &>>$Log_File
validate $? "Enabling MongoDB"

systemctl start mongodb &>>$Log_File
validate $? "Starting MongoDB"