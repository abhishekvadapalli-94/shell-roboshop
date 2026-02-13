#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

if [ $USERID -ne 0 ]; then
    echo "Please run this script with root user access"
    exit 1
fi
mkdir -p $LOGS_FOLDER
VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo "$2 ... FAILURE" | tee -a $LOGS_FILE
        exit 1
    else
        echo "$2 ... SUCCESS" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGS_FILE
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>> $LOGS_FILE
VALIDATE $? "Enabling MongoDB service"

systemctl start mongod &>> $LOGS_FILE
VALIDATE $? "Starting MongoDB service"

sed -i 's/127.0.0.1/0.0.0/g' /etc/mongod.conf &>> $LOGS_FILE
VALIDATE $? "Allowing MongoDB to listen on all interfaces"

systemctl restart mongod &>> $LOGS_FILE
VALIDATE $? "Restarting MongoDB service"