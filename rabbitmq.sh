#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.daws88s.online

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

cp "$SCRIPT_DIR"/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Added RabbitMQ repo"

# Refresh DNF metadata so the new repo is picked up
dnf clean all &>>"$LOGS_FILE"
dnf makecache --refresh &>>"$LOGS_FILE"
VALIDATE $? "Refreshed DNF metadata for RabbitMQ repo"

# If rabbitmq-server is not visible in repos, try the official packagecloud installer
if ! dnf list --showduplicates rabbitmq-server &>>"$LOGS_FILE"; then
    echo "rabbitmq-server not found in configured repos, attempting official repo installer" | tee -a "$LOGS_FILE"
    curl -fsSL https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>>"$LOGS_FILE"
    VALIDATE $? "Added RabbitMQ official repo via packagecloud"
fi

dnf install -y rabbitmq-server &>>"$LOGS_FILE"
VALIDATE $? "Installing RabbitMQ server"

systemctl enable rabbitmq-server &>>"$LOGS_FILE"
systemctl start rabbitmq-server &>>"$LOGS_FILE"
VALIDATE $? "Enabled and started rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$LOGS_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOGS_FILE
VALIDATE $? "created user and given permissions"