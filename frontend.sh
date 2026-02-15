#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$(dirname $(realpath $0))
MONGODB_HOST=mongodb.devopswithabhi.online

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx -y &>>$LOGS_FILE
dnf module enable nginx:1.24 -y &>>$LOGS_FILE
dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx  &>>$LOGS_FILE
VALIDATE $? "Enabled nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Remove default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "Downloaded and unzipped frontend"

# Debug: Check if source file exists
echo "Looking for nginx.conf at: $SCRIPT_DIR/nginx.conf" | tee -a $LOGS_FILE
ls -la $SCRIPT_DIR/nginx.conf &>>$LOGS_FILE

rm -rf /etc/nginx/nginx.conf
cp -v $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOGS_FILE
VALIDATE $? "Copied our nginx conf file"

# Verify the copy worked
echo "Copied file size:" | tee -a $LOGS_FILE
ls -la /etc/nginx/nginx.conf | tee -a $LOGS_FILE

systemctl start nginx
VALIDATE $? "Started Nginx"