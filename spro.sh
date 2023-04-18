#!/bin/bash

tmpDir="/tmp/GenTargets/Targets/"
destroyDir="/tmp/GenTargets/Destroy/"

#Скорости ББ БР
minSpeed=(8000 250 50)
maxSpeed=(10000 1000 250)
targetType=("ББ БР" "К.ракета" "Самолет")

#Координаты круга
xCenter=2500000
yCenter=3600000

#Радиус круга
radius=900000

#Боезапас
rockets=10

declare -A hashArray
declare -A fixedTargets
declare -A indArray
declare -A speedArray
declare -A destroyArray

#Уничтожаемые цели
targetsToDestroy=""

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
            echo 1
        else
            echo 2
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

calcSpeed() {
    local X0=${1%,*}
    local Y0=${1#*,}

    local X1=${2%,*}
    local Y1=${2#*,}

    local speed=$(echo "scale=2; sqrt(($X1-$X0)^2+($Y1-$Y0)^2)" | bc)
    echo $speed
}

while [ 1 ]; do
    sleep 0.5
    #echo "new iter"
    targetsToDestroy=$(ls -t $destroyDir 2>/dev/null)
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

        if [ "${destroyArray[$ind]#*;}" == "n" ]; then
            checkTargetStatus=$(isTargetDestroyed ${destroyArray[$ind]%;*})
            if [ "$checkTargetStatus" == "0" ]; then
                fixedTargets[${destroyArray[$ind]%;*}]="f"
                destroyArray[$ind]="${destroyArray[$ind]%;*};o"
                echo "Промах по цели ID:${destroyArray[$ind]%;*}"
            elif [ "$checkTargetStatus" != "3" ]; then
                destroyArray[$ind]="${destroyArray[$ind]%;*};d"
                echo "Цель ID:${destroyArray[$ind]%;*} уничтожена!"
            fi
        fi

        targetXY=${hashArray[${indArray[$ind]}]#*;}
        targetX=${targetXY%,*}
        targetY=${targetXY#*,}
        distToTarget=$(calcSpeed "$targetXY" "$xCenter,$yCenter")
        #echo "Dist: $distToTarget Coords: $targetXY TEST: ${hashArray[${indArray[$ind]}]}"
        for ((i = 0; i != 1; i++)); do
            if [ ${speedArray[$ind]%.*} -ge ${minSpeed[$i]} ] &&
                [ ${speedArray[$ind]%.*} -le ${maxSpeed[$i]} ] &&
                [ ${distToTarget%.*} -le $radius ]; then

                if [ "${fixedTargets[${indArray[$ind]}]}" == "" ]; then
                    fixedTargets[${indArray[$ind]}]="f"
                    echo "Обнаружена цель ID:${indArray[$ind]} с координатами ${targetX} ${targetY} Speed: ${speedArray[$ind]}"
                fi

                if [ "${fixedTargets[${indArray[$ind]}]}" != "a" ]; then
                    if [ "$rockets" -gt "0" ]; then

                        echo "Выстрел по цели ID:${indArray[$ind]}"
                        fixedTargets[${indArray[$ind]}]="a"
                        j=0
                        while [ "${destroyArray[$j]#*;}" == "n" ]; do
                            ((j++))
                        done
                        destroyArray[$j]="${indArray[$ind]};n"
                        touch "${destroyDir}${indArray[$ind]}"
                        ((rockets--))
                    else
                        echo "Боезапас исчерпан"
                    fi
                fi
            fi
        done

        ((ind++))
    done

done
