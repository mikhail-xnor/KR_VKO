#!/bin/bash

Echo() {
    echo "$1 sended" | rev
}

isInSector() {
    pi=$(echo "h=10;4*a(1)" | bc -l)
    yOffset=$(expr $2 - $yCenter)
    xOffset=$(expr $1 - $xCenter)
    ugol=$(echo "scale=0; a($yOffset/$xOffset)*180/$pi" | bc -l)

    if [ "$xOffset" -gt "0" ] &&
        [ "$yOffset" -lt "0" ]; then
        ugol=$(expr $ugol + 360)
    elif [ "$xOffset" -lt "0" ]; then
        ugol=$(expr $ugol + 180)
    fi

    if [ "$startAngle" -lt "$endAngle" ]; then
        if [ "$ugol" -gt "$startAngle" ] &&
            [ "$ugol" -lt "$endAngle" ]; then
            echo 1
            return
        fi
    else
        if [ "$ugol" -gt "$endAngle" ] ||
            [ "$ugol" -lt "$startAngle" ]; then
            echo 1
            return
        fi
    fi
    echo 0
}

calcSpeed() {
    local X0=${1%,*}
    local Y0=${1#*,}

    local X1=${2%,*}
    local Y1=${2#*,}

    local speed=$(echo "scale=2; sqrt(($X1-$X0)^2+($Y1-$Y0)^2)" | bc)
    echo $speed
}

isMovesToSpro() {
    in_spro=0
    d1=$(calcSpeed "$sproX,$sproY" "$1,$2")
    d1=${d1%.*}
    d2=$(calcSpeed "$sproX,$sproY" "$3,$4")
    d2=${d2%.*}
    if [ "$d2" -lt "$d1" ]; then
        k=$(echo "($4-$2)/($3-$1)" | bc -l)
        b=$(echo "$2- $k*$1" | bc -l)
        d=$(echo "(- $k*$sproX+$sproY- $b)/(sqrt($k*$k+1))" | bc -l)
        d=$(echo ${d#-})
        if (($(echo "$d<$sproR" | bc -l))); then
            in_spro=1
        fi
    fi
    echo $in_spro
}

isTargetDestroyed() {
    isTargetActive=0
    isDestroyFileExist=0
    tInd=0
    while [ "$tInd" -lt "30" ]; do
        if [ "${indArray[$tInd]}" == "$1" ]; then
            if [ "${speedArray[$tInd]%.*}" -gt "0" ]; then
                isTargetActive=1
            else
                echo 3 #Ожидание запуска противоракеты (частный случай), координаты цели могли не успеть обновиться
                return
            fi
        fi
        ((tInd++))
    done
    for i in $targetsToDestroy; do
        if [ "$i" == "$1" ]; then
            isDestroyFileExist=1
        fi
    done
    if [ "$isTargetActive" == "0" ]; then
        if [ "$isDestroyFileExist" == "0" ]; then
            echo 1 #Цель была уничтожена
        else
            echo 2 #Цель умерла по естественным причинам :)
        fi
        return
    fi
    if [ "$isTargetActive" == "1" ] &&
        [ "$isDestroyFileExist" == "1" ]; then
        echo 3 #Ожидание запуска противоракеты
        return
    fi
    echo 0 #Промах
}