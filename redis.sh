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

dnf module disable redis -y &>> $LOGS_FILE
dnf module enable redis:7 -y &>> $LOGS_FILE

VALIDATE $? "Enabling Redis 7 module"

dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installing Redis"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>> $LOGS_FILE
VALIDATE $? "Allowing Redis to listen on all interfaces and disabling protected mode"

systemctl enable redis &>> $LOGS_FILE
VALIDATE $? "Enabling Redis service"

systemctl start redis &>> $LOGS_FILE
VALIDATE $? "Starting Redis service"


