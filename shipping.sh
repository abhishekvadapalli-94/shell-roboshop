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

dnf install maven -y &>> $LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $? "Adding roboshop user"
else 
    echo -e "roboshop user already exists ... $Y Skipping user creation $N" 
fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading shipping code"

cd /app 
VALIDATE $? "Changing to application directory"

rm -rf /app/* &>> $LOGS_FILE
VALIDATE $? "Cleaning application directory"

unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Extracting application code"

cd /app 
mvn clean package &>> $LOGS_FILE
VALIDATE $? "Building application code"

mv target/shipping-1.0.jar shipping.jar &>> $LOGS_FILE
VALIDATE $? "Renaming JAR file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOGS_FILE
VALIDATE $? "creating systemctl service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Installing MySQL client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>> $LOGS_FILE
if [ $? -ne 0 ]; then

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGS_FILE
VALIDATE $? "Creating shipping database schema"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOGS_FILE
VALIDATE $? "Creating shipping database user"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOGS_FILE
VALIDATE $? "Inserting master data into shipping database"
else
    echo -e "shipping database already exists ... $Y Skipping database creation $N" 
fi

systemctl enable shipping &>> $LOGS_FILE
systemctl start shipping &>> $LOGS_FILE
VALIDATE $? "Starting shipping service"