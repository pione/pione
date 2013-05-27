#!/bin/sh

N=100

if [ "$1" != "" ]
then
    N=$1
fi

echo "test $N times"
RESULT=endurance-test-result.txt
TIME=endurance-test-time.txt

echo "number, result" > ${RESULT}
echo "number, real, user, sys" > ${TIME}

for i in `seq 1 $N`
do
    echo "--- ${i} ---"
    timeout -s 9 10 time --quiet --append -o ${TIME} -f "${i}, %e, %U, %S"  pione-client example/HelloWorld/ --rehearse
    echo "${i}, $?" >> ${RESULT}
    sleep 1
    pkill -KILL -fe pione-
done
