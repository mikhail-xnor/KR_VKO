#!/bin/bash

[ $EUID == 0 ] && echo "Систему ВКО нельзя запускать с правами администратора!" && exit 1
[ "$(uname -s)" != "Linux" ] && echo "Стартовая система отлична от Linux!" && exit 1
[ "$SHELL" != "/bin/bash" ] && echo "Командный интерпретатор отличен от /bin/bash!" && exit 1

#Наименование файлов
filesName=$(echo $0 | rev | cut -d '/' -f 1 | cut -d '.' -f 2 | rev)

[ $(ps aux | grep "$filesName" | grep -v "grep" | wc -l) -gt 2 ] && echo "Один экземпляр уже запущен!" && exit 1

#Директория целей
tmpDir="/tmp/GenTargets/Targets/"
destroyDir="/tmp/GenTargets/Destroy/"

#Связь
pingFile=messages/ping$filesName

#Скорости ББ БР
minSpeed=(8000 251 50)
maxSpeed=(10000 1000 250)
targetType=("ББ БР" "К.ракета" "Самолет")

#Координаты круга
xCenter=2750000
yCenter=2886000

#Радиус круга
radius=400000

#Боезапас
rockets=20

declare -A hashArray
declare -A fixedTargets
declare -A indArray
declare -A speedArray
declare -A destroyArray

#Уничтожаемые цели
targetsToDestroy=""

source ./helpFunctions.sh

while [ 1 ]; do
    
    echo "live" > $pingFile
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
                Echo "Промах по цели ID:${destroyArray[$ind]%;*}"
            elif [ "$checkTargetStatus" != "3" ]; then
                destroyArray[$ind]="${destroyArray[$ind]%;*};d"
                Echo "Цель ID:${destroyArray[$ind]%;*} уничтожена!"
            fi
        elif [ "${destroyArray[$ind]#*;}" == "w" ]; then
            destroyArray[$ind]="${destroyArray[$ind]%;*};n"
        fi

        targetXY=${hashArray[${indArray[$ind]}]#*;}
        targetX=${targetXY%,*}
        targetY=${targetXY#*,}
        distToTarget=$(calcSpeed "$targetXY" "$xCenter,$yCenter")
        #echo "Dist: $distToTarget Coords: $targetXY TEST: ${hashArray[${indArray[$ind]}]}"
        for ((i = 1; i != 3; i++)); do
            if [ ${speedArray[$ind]%.*} -ge ${minSpeed[$i]} ] &&
                [ ${speedArray[$ind]%.*} -le ${maxSpeed[$i]} ] &&
                [ ${distToTarget%.*} -le $radius ]; then

                if [ "${fixedTargets[${indArray[$ind]}]}" == "" ]; then
                    fixedTargets[${indArray[$ind]}]="f"
                    Echo "Обнаружена цель ID:${indArray[$ind]} с координатами ${targetX} ${targetY}"
                fi

                if [ "${fixedTargets[${indArray[$ind]}]}" != "a" ]; then
                    if [ "$rockets" -gt "0" ]; then

                        Echo "Выстрел по цели ID:${indArray[$ind]}"
                        fixedTargets[${indArray[$ind]}]="a"
                        j=0
                        while [ "${destroyArray[$j]#*;}" != "" ] &&
                            [ "${destroyArray[$j]#*;}" != "d" ]; do
                            ((j++))
                        done
                        destroyArray[$j]="${indArray[$ind]};w"
                        touch "${destroyDir}${indArray[$ind]}"
                        ((rockets--))
                    elif [ "$rockets" == "0" ]; then
                        Echo "Боезапас исчерпан"
                        ((rockets--))
                    fi
                fi
            fi
        done

        ((ind++))
    done
    sleep 0.5
done
