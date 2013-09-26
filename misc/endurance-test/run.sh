#!/bin/sh

N=100
LOCATION=example/HelloWorld/
CLEAR=1
LIMIT=10

usage() {
    echo "Usage: run.sh [-n NUMBER] [-l LOCATION] [-z] [--limit SEC]"
    echo "         -n NUMBER     do the test NUMBER times"
    echo "         -l LOCATION   location of process document"
    echo "         -z            don't clear output location"
    echo "         --limit SEC   timeout after SEC seconds"
    exit 1
}

OPT=`getopt -o n:l:z -l limit: -- "$@"`; [ $? -ne 0 ] && usage
eval set -- "$OPT"

while true
do
    case $1 in
	-n)
	    N=$2; shift 2
	    ;;
	-l)
	    LOCATION="$2"; shift 2
	    ;;
	-z)
	    CLEAR=0; shift
	    ;;
	--limit)
	    LIMIT=$2; shift 2
	    ;;
	--)
	    shift; break
	    ;;
	*)
	    usage
	    ;;
    esac
done

echo "endurance-test($N times)"
echo "  location: $LOCATION"
echo "  limit: $LIMIT"
echo "  clear output: $CLEAR (1: true, 0: faluse)"
RESULT=endurance-test-result.txt
TIME=endurance-test-time.txt

echo "number, result" > ${RESULT}
echo "number, real, user, sys" > ${TIME}

for i in `seq 1 $N`
do
    echo "--- ${i} ---"
    if [ $CLEAR -eq 1 ]
    then
	rm -rf output
    fi
    timeout -s 9 $LIMIT time --quiet --append -o ${TIME} -f "${i}, %e, %U, %S"  pione-client ${LOCATION} --rehearse
    echo "${i}, $?" >> ${RESULT}
    sleep 1
    pkill -KILL -fe pione-
done
