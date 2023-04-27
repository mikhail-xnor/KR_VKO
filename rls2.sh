#!/bin/bash

tmpDir="/tmp/GenTargets/Targets/"

#Наименование файлов
filesName=$(echo $0 | rev | cut -d '/' -f 1 | cut -d '.' -f 2 | rev)

#Связь
pingFile=messages/ping$filesName

#Скорости ББ БР
minSpeed=(8000 251 50)
maxSpeed=(10000 1000 250)
targetType=("ББ БР" "К.ракета" "Самолет")

#Координаты круга
xCenter=3956000
yCenter=3863000

#Радиус круга
radius=3000000

#Азимут
azimutAngle=270

#Угол обзора
angle=120

#Координаты СПРО
sproX=2545000
sproY=3636000
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

source ./helpFunctions.sh

while [ 1 ]; do
    
    echo "live" > $pingFile
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
                Echo "Обнаружена цель ID:${indArray[$ind]} с координатами ${targetX} ${targetY}"
                
                lastTargetXY=${hashArray[${indArray[$ind]}]%;*}
                lastTargetX=${lastTargetXY%,*}
                lastTargetY=${lastTargetXY#*,}
                moveToSpro=$(isMovesToSpro $lastTargetX $lastTargetY $targetX $targetY)
                if (($moveToSpro == 1)); then
                    Echo "Цель ID:${indArray[$ind]} движется в направлении СПРО"
                fi
            fi
        done
        ((ind++))
    done
    sleep 0.3
done
