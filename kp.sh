#!/bin/bash

#Проверка работоспособности каждые
pingTimeout=15
pingStatus=1
pingDelay=5

#Общий лог
logFile=logs/mainLog

#СПРО
sproStatus=0
pingSpro=messages/pingSpro
messagesSpro=messages/spro
logSpro=logs/spro
sproLogLine=0
: >$pingSpro


# для отладки
: >$logSpro
: >$logFile


logFileRls3=logs/rls3
logFileZrdn1=logs/zrdn1
: >$logFileRls3
: >$logFileZrdn1

#$(spro.sh 1>$logFileSpro &)
#$(rls1.sh 1>$logFileRls1 &)
#$(zrdn1.sh 1>$logFileZrdn1 &)

formatLogRow() {
    systemTime=$(date +"%d.%m %H:%M:%S")
    echo "$systemTime $1 $2"
}

echoLog() {
    echo "$1" >> $logFile
    echo "$1" >> $2
}


while :
do
    sleep 0.5

    if [ $pingStatus -ge $pingTimeout ]; then
        pingStatus=1
        echo "ping" > $pingSpro
    elif [ $pingStatus -ge $pingDelay ]; then
        if [ "$(cat $pingSpro)" == "live" ]; then
            if [ $sproStatus == "0" ] ||
                [ $sproStatus == "3" ]; then
                sproStatus=2
            else
                sproStatus=1
            fi
        else
            if [ $sproStatus == "1" ] ||
                [ $sproStatus == "2" ]; then
                sproStatus=3
            else
                sproStatus=0
            fi
        fi
    fi

    
    if [ $sproStatus == "2" ]; then
        msg=$(formatLogRow "СПРО" "работоспособность восстановлена")
        echoLog "$msg" $logSpro
    elif [ $sproStatus == "3" ]; then
        msg=$(formatLogRow "СПРО" "вышла из строя")
        echoLog "$msg" $logSpro
    fi

    if [ $sproStatus == "1" ]; then
        log=$(cat $messagesSpro | tail -n $(expr $(cat $messagesSpro | wc -l) - $sproLogLine))
        OLDIFS=$IFS
        IFS=$'\n'
        for line in $log; do
            if [ "$(echo "$line" | cut -d ' ' -f 1 | rev)" == "sended" ]; then
                msg=$(echo "$line" | cut -d ' ' -f 2- | rev)
                msg=$(formatLogRow "СПРО" $msg)
                echoLog "$msg" $logSpro
                ((sproLogLine++))
            fi
        done
        IFS=$OLDIFS
    fi


    ((pingStatus++))
done