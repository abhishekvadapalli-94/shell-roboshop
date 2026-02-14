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

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling NodeJS default version"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling NodeJS 20 version"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $? "Adding roboshop user"
else 
    echo -e "roboshop user already exists ... $Y Skipping user creation $N" 
fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue code"

cd /app 
VALIDATE $? "Changing to application directory"

rm -rf /app/* &>> $LOGS_FILE
VALIDATE $? "Cleaning application directory"

unzip /tmp/catalogue.zip &>> $LOGS_FILE
VALIDATE $? "Extracting application code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing application dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGS_FILE
VALIDATE $? "creating systemctl service"

systemctl daemon-reload &>> $LOGS_FILE
systemctl enable catalogue &>> $LOGS_FILE
systemctl start catalogue &>> $LOGS_FILE

VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGS_FILE
dnf install mongodb-mongosh -y &>> $LOGS_FILE


INDEX=$(mongosh --host $MONGO_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -eq -1 ]; then
    mongosh --host $MONGO_HOST </app/db/master-data.js
    VALIDATE $? "Inserting data into MongoDB"
else
    echo -e "catalogue database already exists ... $Y Skipping data insertion $N"
fi

systemctl restart catalogue &>> $LOGS_FILE
VALIDATE $? "Restarting catalogue service"