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

dnf install python3 gcc python3-devel -y &>> $LOGS_FILE
VALIDATE $? "Installing Python and Development Tools"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $? "Adding roboshop user"
else 
    echo -e "roboshop user already exists ... $Y Skipping user creation $N" 
fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "Downloading payment code"

cd /app 
VALIDATE $? "Changing to application directory"

rm -rf /app/* &>> $LOGS_FILE
VALIDATE $? "Cleaning application directory"

unzip /tmp/payment.zip &>> $LOGS_FILE
VALIDATE $? "Extracting application code"

cd /app 
pip3 install -r requirements.txt &>> $LOGS_FILE
VALIDATE $? "Installing application dependencies"


cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> $LOGS_FILE
VALIDATE $? "creating systemctl service"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Reloading systemctl daemon"

systemctl enable payment &>> $LOGS_FILE
systemctl start payment &>> $LOGS_FILE
VALIDATE $? "Enabling and starting payment service"
