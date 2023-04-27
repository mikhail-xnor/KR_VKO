#!/bin/bash

#Проверка работоспособности каждые
pingTimeout=25
pingStatus=$pingTimeout
pingDelay=5

#Общий лог
mainLogFile=logs/mainLog


#Сообщения от систем
messagesFile=messages/
#Пинг файл систем
pingFile=messages/ping
#Лог файл систем
logFile=logs/
#Наименования файлов систем
systemsNames=( "rls1" "rls2" "rls3" "spro" "zrdn1" "zrdn2" "zrdn3" )
#Наименовния систем
systemsLabels=( "РЛС1" "РЛС2" "РЛС3" "СПРО" "ЗРДН1" "ЗРДН2" "ЗРДН3" )
#Статусы систем
systemsStatus=( 0 0 0 0 0 0 0 )
#Количество считанных сообщений
systemsMsgRead=( 0 0 0 0 0 0 0 )


#СПРО
#sproStatus=0
#pingSpro=messages/pingSpro
#messagesSpro=messages/spro
#logSpro=logs/spro
#sproLogLine=0


formatLogRow() {
    systemTime=$(date +"%d.%m %H:%M:%S")
    echo "$systemTime $1 $2"
}

echoLog() {
    echo "$1" >> $mainLogFile
    echo "$1" >> $2
}


while :
do
    for i in ${!systemsNames[@]}; do
        if [ $pingStatus -ge $pingTimeout ]; then
            pingStatus=1
            echo "ping" > "${pingFile}${systemsNames[$i]}"
        elif [ $pingStatus -ge $pingDelay ]; then
            if [ "$(cat ${pingFile}${systemsNames[$i]})" == "live" ]; then
                if [ ${systemsStatus[$i]} == "0" ] ||
                    [ ${systemsStatus[$i]} == "3" ]; then
                    systemsStatus[$i]=2
                else
                    systemsStatus[$i]=1
                fi
            else
                if [ ${systemsStatus[$i]} == "1" ] ||
                    [ ${systemsStatus[$i]} == "2" ]; then
                    systemsStatus[$i]=3
                else
                    systemsStatus[$i]=0
                fi
            fi
        fi
        #Запись лога
        if [ ${systemsStatus[$i]} == "2" ]; then
            msg=$(formatLogRow "${systemsLabels[$i]}" "работоспособность восстановлена")
            echoLog "$msg" "${logFile}${systemsNames[$i]}"
        elif [ ${systemsStatus[$i]} == "3" ]; then
            msg=$(formatLogRow "${systemsLabels[$i]}" "вышла из строя")
            echoLog "$msg" "${logFile}${systemsNames[$i]}"
        fi
        if [ ${systemsStatus[$i]} == "1" ]; then
            log=$(cat "${messagesFile}${systemsNames[$i]}" | tail -n $(expr $(cat "${messagesFile}${systemsNames[$i]}" | wc -l) - ${systemsMsgRead[$i]}))
            OLDIFS=$IFS
            IFS=$'\n'
            for line in $log; do
                if [ "$(echo "$line" | cut -d ' ' -f 1 | rev)" == "sended" ]; then
                    msg=$(echo "$line" | cut -d ' ' -f 2- | rev)
                    msg=$(formatLogRow "${systemsLabels[$i]}" $msg)
                    echoLog "$msg" "${logFile}${systemsNames[$i]}"
                    ((${systemsMsgRead[$i]}++))
                fi
            done
            IFS=$OLDIFS
        fi
    done

    ((pingStatus++))
    sleep 0.5
done