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

dnf install mysql-server -y &>> $LOGS_FILE
VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld &>> $LOGS_FILE
VALIDATE $? "Enabling MySQL service"

systemctl start mysqld &>> $LOGS_FILE
VALIDATE $? "Starting MySQL service"

mysql_secure_installation --set-root-pass roboshop@1 &>> $LOGS_FILE
VALIDATE $? "Setting MySQL root password"
