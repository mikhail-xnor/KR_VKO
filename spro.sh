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


isTargetDestroyed() {
tInd=0
while [ "$tInd" -lt "30" ]; do

(( tInd++ ))
done
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

while [ 1 ]
do
sleep 0.8
#echo "new iter"
tmpTarget=$(ls -t $tmpDir 2>/dev/null | head -n 30)
ind=0
for i in $tmpTarget
do
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
while [ "$ind" -lt "30" ]
do
targetXY=${hashArray[${indArray[$ind]}]#*;}
targetX=${targetXY%,*}
targetY=${targetXY#*,}
distToTarget=$(calcSpeed "$targetXY" "$xCenter,$yCenter")
#echo "Dist: $distToTarget Coords: $targetXY TEST: ${hashArray[${indArray[$ind]}]}"
for ((i=0; i!=1; i++)); do
if [ ${speedArray[$ind]%.*} -ge ${minSpeed[$i]} ] &&
[ ${speedArray[$ind]%.*} -le ${maxSpeed[$i]} ] &&
[ ${distToTarget%.*} -le $radius ]; then

if [ "${fixedTargets[${indArray[$ind]}]}" == "" ]; then
fixedTargets[${indArray[$ind]}]="f"
echo "Обнаружена цель ID:${indArray[$ind]} с координатами ${targetX} ${targetY} Speed: ${speedArray[$ind]}"
fi

if [ "$rockets" -ge "0" ] &&
[ "${fixedTargets[${indArray[$ind]}]}" != "a" ]; then

echo "Выстрел по цели ID:${indArray[$ind]}"
fixedTargets[${indArray[$ind]}]="a"
j=0
while [ "${destroyArray[$j]#*;}" == "a" ]; do
(( j++ ))
done
destroyArray[$j]="${indArray[$ind]};a"
touch "${destroyDir}${indArray[$ind]}"
(( rockets-- ))
else
echo "Боезапас исчерпан"
fi

fi
done

if [ "${destroyArray[$j]#*;}" == "a" ] &&
[ "$(isTargetDestroyed ${destroyArray[$j]%;*})" == "1" ]; then
destroyArray[$j]="${destroyArray[$j]%;*};d"
echo "Цель с ID:${destroyArray[$j]%;*} уничтожена!"
fi

(( ind++ ))
done

done