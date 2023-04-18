#!/bin/bash

tmpDir="/tmp/GenTargets/Targets/"

#Скорости ББ БР
minSpeed=(8000 250 50)
maxSpeed=(10000 1000 250)
targetType=("ББ БР" "К.ракета" "Самолет")

#Координаты круга
xCenter=6000000
yCenter=7000000

#Радиус круга
radius=7000000

#Азимут
azimutAngle=0

#Угол обзора
angle=90

#Координаты СПРО
sproX=2500000
sproY=3600000
sproR=900000

#Углы сектора относительно начала координат
startAngle=$(expr 450 - $azimutAngle - $angle / 2)
startAngle=$(expr $startAngle % 360)
endAngle=$(expr 450 - $azimutAngle + $angle / 2)
endAngle=$(expr $endAngle % 360)

declare -A hashArray
declare -A fixedTargets
declare -A indArray
declare -A speedArray

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

while [ 1 ]; do
    sleep 0.8
    #echo "new iter"
    tmpTarget=$(ls -t $tmpDir 2>/dev/null | head -n 30)
    ind=0
    for i in $tmpTarget; do
        targetId=${i:12:6}
        indArray[$ind]=$targetId
        targetXY=$(cat $tmpDir$i)
        targetX=${targetXY%,*}
        targetY=${targetXY#*,}
        if [ "${hashArray[$targetId]}" != "" ]; then
            speedArray[$ind]=$(calcSpeed ${hashArray[$targetId]#*;} "${targetX:1},${targetY:1}")
        else
            speedArray[$ind]=0
        fi
        hashArray[$targetId]="${hashArray[$targetId]#*;};${targetX:1},${targetY:1}"
        #echo "Target: ${indArray[$ind]}: ${hashArray[${indArray[$ind]}]} Speed: ${speedArray[$ind]}"
        ind=$(expr $ind + 1)
    done

    ind=0
    while [ "$ind" -lt "30" ]; do
        targetXY=${hashArray[${indArray[$ind]}]#*;}
        targetX=${targetXY%,*}
        targetY=${targetXY#*,}
        distToTarget=$(calcSpeed "$targetXY" "$xCenter,$yCenter")
        inSector=$(isInSector $targetX $targetY)
        #echo "Dist: $distToTarget Coords: $targetXY TEST: ${hashArray[${indArray[$ind]}]}"
        for ((i = 0; i != 1; i++)); do
            if [ "${fixedTargets[${indArray[$ind]}]}" != "f" ] &&
                [ ${speedArray[$ind]%.*} -ge ${minSpeed[$i]} ] &&
                [ ${speedArray[$ind]%.*} -le ${maxSpeed[$i]} ] &&
                [ ${distToTarget%.*} -le $radius ] &&
                [ "$inSector" == "1" ]; then
                fixedTargets[${indArray[$ind]}]="f"
                echo "Обнаружена цель ID:${indArray[$ind]} с координатами ${targetX} ${targetY} Speed: ${speedArray[$ind]}"
                lastTargetXY=${hashArray[${indArray[$ind]}]%;*}
                lastTargetX=${lastTargetXY%,*}
                lastTargetY=${lastTargetXY#*,}

                moveToSpro=$(isMovesToSpro $lastX $lastY $X $Y)
                if (($moveToSpro == 1)); then
                    echo "Цель ID:${indArray[$ind]} движется в направлении СПРО"
                fi
            fi
        done
        ((ind++))
    done

done
