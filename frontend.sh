#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
SCRIPT_DIR=$PWD
MONGO_HOST="mongodb.devopswithabhi.online"
MYSQL_HOST="mysql.devopswithabhi.online"

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

dnf module install nginx -y &>> $LOGS_FILE
VALIDATE $? "Installing Nginx"

dnf module enable nginx:1.24 -y &>> $LOGS_FILE
VALIDATE $? "Enabling Nginx 1.24 module"

dnf install nginx -y &>> $LOGS_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $LOGS_FILE
systemctl start nginx &>> $LOGS_FILE
VALIDATE $? "Enabling and Starting Nginx"

rm -rf /usr/share/nginx/html/* &>> $LOGS_FILE
VALIDATE $? "Cleaning Nginx default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html
VALIDATE $? "Changing to Nginx content directory"

unzip /tmp/frontend.zip &>> $LOGS_FILE
VALIDATE $? "Extracting frontend code"

rm -rf /usr/share/nginx/html/* &>> $LOGS_FILE
VALIDATE $? "Cleaning Nginx content directory"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOGS_FILE
VALIDATE $? "Copying Nginx configuration file"

systemctl restart nginx &>> $LOGS_FILE
VALIDATE $? "Restarting Nginx"
