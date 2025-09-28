#!bin/bash

G="\e[32m"
R="\e[31m"
O="\e[33m"
N="\e[0m"

USERID=$(id -u)

Logs_Folder="/var/logs/shell-roboshop"
Script_Name=$( echo 0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"
mongodb_host=mongodb.pracdevops.store
SCRIPT_DIR=$PWD

mkdir -p $Logs_Folder

echo "Script started execution at $(date)" | tee - a &>>$Log_File


if [ $USERID -ne 0 ]; then
    echo -e "$R Error...$N Run this script with root privelege"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 has failed...$R Error $N" | tee -a &>>$Log_File
        exit 1
    else
        echo -e "$2 is $G Successful $N" | tee -a &>>$Log_File
    fi
}

dnf module disable nodejs -y &>>$Log_File
validate $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$Log_File
validate $? "Enabling NodeJS"

dnf install nodejs -y $>>$Log_File
validate $? "Installing NodeJS"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo -e "User already $G exists $N"
fi 

mkdir -p /app
validate $? "Creating app directory"

curl -o "/tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip"
validate $? "Downloading catalogue application"

cd /app
validate $? "Changing to app directory"

rm -rf /app/*
validate $? "Removing exisiting code"

unzip /tmp/catalogue.zip &>>$Log_File
validate $? "Unzipping catalogue app"

npm install &>>$Log_File
validate $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Copying systemctl service"

systemctl daemon-reload &>>$Log_File
validate $? "Daemon reload"

systemctl enable catalogue &>>$Log_File
validate $? "Enabling catalogue"

systemctl start catalogue &>>$Log_File
validate $? "Starting catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copying mongo repo"

dnf install mongodb-mongosh -y &>>$Log_File
validate $? "MongoDB Client Installation"

#To prevent duplication of loading of products
INDEX=$(mongosh mongodb.pracdevops.store --quiet --eval "db.getMongo().getDBNames().indexOf('Catalogue')")
if [ $INDEX -le 0]; then
    mongosh --host $mongodb_host </app/db/master-data.js $>>$Log_File
    validate $? "Loading catalogue products"
else
    echo -e "Catalogue products $G already exist $N , skipping"
fi

systemctl restart catalogue &>>$Log_File
validate $? "Restarting catalogue"

