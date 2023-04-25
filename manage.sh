#!/bin/bash

kp=./kp.sh
spro=./spro.sh
messagesSpro=messages/spro

manageSystem=""
infoSystem=""

if [ $1 == "" ]; then
    $kp &
else
    if [ $1 == "spro" ]; then
        manageSystem=$spro
        infoSystem=$messagesSpro
    fi

    if [ $2 == "start" ]; then
        $manageSystem 1>>$infoSystem &
    elif [ $2 == "stop" ]; then
        kill -9 $(ps aux | grep "spro.sh" | head -n 1 | awk '{ print $2 }')
    fi
fi
