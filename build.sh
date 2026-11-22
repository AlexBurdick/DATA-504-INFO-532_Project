#!/bin/bash
set -x

cd ~/DATA-504-INFO-532_Project || exit 1

JDBC=/usr/lib/oracle/18.3/client64/lib/ojdbc8.jar

echo "Compiling..."
javac -cp .:$JDBC *.java

if [ $? -ne 0 ]; then
    echo "Compile failed."
    exit 1
fi

echo "Running..."
java -cp .:$JDBC Project