#!/bin/bash

printHelp() {
    echo "Программа для управления системами ВКО"
    echo ""
    echo "Для запуска конкретной системы выполнить команду:"
    echo "./manage.sh spro start"
    echo ""
    echo "Для остановки конкретной системы выполнить команду:"
    echo "./manage.sh spro stop"
    echo ""
    echo "Для запуска всех систем выполнить команду:"
    echo "./manage.sh all start"
    echo ""
    echo "Для остановки всех систем выполнить команду:"
    echo "./manage.sh all stop"
    echo ""
    echo "Для вывода статуса всех систем выполнить команду:"
    echo "./manage.sh all status"
    echo ""
    echo "Для вывода данной справки выполнить команду:"
    echo "./manage.sh help"
}

systemsNames=( "kp" "rls1" "rls2" "rls3" "spro" "zrdn1" "zrdn2" "zrdn3" )

systems["kp"]="./kp.sh"
systems["rls1"]="./rls1.sh"
systems["rls2"]="./rls2.sh"
systems["rls3"]="./rls3.sh"
systems["spro"]="./spro.sh"
systems["zrdn1"]="./zrdn1.sh"
systems["zrdn2"]="./zrdn2.sh"
systems["zrdn3"]="./zrdn3.sh"

systemMessages=messages/
if [ $1 == "help" ]; then
    printHelp
elif [ $1 == "all" ]; then
    if [ $2 == "start" ]; then
        for i in ${!systemsNames[@]}; do
            if [ $i == 0 ]; then
                ${systems[${systemsNames[$i]}]} &
            else
                ${systems[${systemsNames[$i]}]} 1>>"${systemMessages}${systemsNames[$i]}" &
            fi
        done
        echo "Все системы активированы"
    elif [ $2 == "stop" ]; then
        for sys in ${systemsNames[@]}; do
            kill -9 $(ps aux | grep "$sys" | head -n 1 | awk '{ print $2 }') &>/dev/null
        done
        echo "Все системы выключены"
    elif [ $2 == "status" ]; then
        echo "status"
    else 
        echo "Передан некорректный аргумент 2"
    fi
elif [ $1 != "" ]; then
    manageSystem=${systems["$1"]}
    if [ $manageSystem != "" ]; then
        if [ $2 == "start" ]; then
            $manageSystem 1>>"${systemMessages}$1" &
            echo "Система $1 активирована"
        elif [ $2 == "stop" ]; then
            kill -9 $(ps aux | grep "$1" | head -n 1 | awk '{ print $2 }') &>/dev/null
            echo "Система $1 выключена"
        else 
            echo "Передан некорректный аргумент 2"
        fi
    else
        echo "Передан некорректный аргумент 1"
    fi
else
    printHelp
fi
