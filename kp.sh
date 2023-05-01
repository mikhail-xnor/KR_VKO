#!/bin/bash

[ $EUID == 0 ] && echo "Систему ВКО нельзя запускать с правами администратора!" && exit 1
[ "$(uname -s)" != "Linux" ] && echo "Стартовая система отлична от Linux!" && exit 1
[ "$SHELL" != "/bin/bash" ] && echo "Командный интерпретатор отличен от /bin/bash!" && exit 1

#Наименование файлов
filesName=$(echo $0 | rev | cut -d '/' -f 1 | cut -d '.' -f 2 | rev)

[ $(ps aux | grep "$filesName" | grep -v "grep" | wc -l) -gt 2 ] && echo "Один экземпляр уже запущен!" && exit 1

#Проверка работоспособности каждые
pingTimeout=25
pingStatus=$pingTimeout
pingDelay=5

#Общий лог
mainLogFile=logs/mainLog

#Подключение БД
databasePath=db/dbVKOLogs.db

#Создание таблиц БД
sqlInitDbPath=createDB.sql

#Временный лог
tmpLogFile=temp/logFile

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

formatLogRow() {
    systemTime=$(date +"%d.%m %H:%M:%S")
    echo "$systemTime $1 $2"
}

echoLog() {
    echo "$1" >> $mainLogFile
    echo "$1" >> $2
    sqlite3 $databasePath "INSERT INTO log (msg) VALUES ('$1')"
}

if [ ! -f $databasePath ]; then
    sqlite3 $databasePath < $sqlInitDbPath
fi

#trap "closeDb" EXIT

while :
do
    for i in ${!systemsNames[@]}; do
        if [ $pingStatus -ge $pingTimeout ]; then
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
            systemsStatus[$i]=1
            msg=$(formatLogRow "${systemsLabels[$i]}" "работоспособность восстановлена")
            echoLog "$msg" "${logFile}${systemsNames[$i]}"
        elif [ ${systemsStatus[$i]} == "3" ]; then
            systemsStatus[$i]=0
            msg=$(formatLogRow "${systemsLabels[$i]}" "вышла из строя")
            echoLog "$msg" "${logFile}${systemsNames[$i]}"
        fi
        if [ ${systemsStatus[$i]} == "1" ]; then
            cp "${messagesFile}${systemsNames[$i]}" $tmpLogFile
            linesNumber=$(cat $tmpLogFile | wc -l)
            if [ $linesNumber -gt ${systemsMsgRead[$i]} ]; then
                log=$(cat $tmpLogFile | tail -n $(expr $linesNumber - ${systemsMsgRead[$i]}))
                OLDIFS=$IFS
                IFS=$'\n'
                lineCounter=${systemsMsgRead[$i]}
                for line in $log; do
                    if [ "$(echo "$line" | cut -d ' ' -f 1 | rev)" == "sended" ]; then
                        msg=$(echo "$line" | cut -d ' ' -f 2- | rev)
                        msg=$(formatLogRow "${systemsLabels[$i]}" $msg)
                        echoLog "$msg" "${logFile}${systemsNames[$i]}"
                        ((lineCounter++))
                    fi
                done
                systemsMsgRead[$i]=$lineCounter
                IFS=$OLDIFS
            fi
        fi
    done
    if [ $pingStatus -ge $pingTimeout ]; then
        pingStatus=1
    else
        ((pingStatus++))
    fi
    sleep 0.5
done