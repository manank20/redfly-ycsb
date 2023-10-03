#! /bin/bash

# Arguments in order: (r/d) redis or dragonfly, (a/b/c/d/e/f) workload type, (int) record count optional, (int) operation count optional
# example invocation $ ./start.sh r a 1000000 2000000 # runs redis benchmark with workload a, 1 mil record count and 2 mil op count

YCSB_BASE="/mnt/io_uring/YCSB"
YCSC_SH="${YCSB_BASE}/bin/ycsb.sh"
WORKLOAD_DIR="${YCSB_BASE}/workloads"
SRV=""
WORKLOAD_TYPE="workload$2"
RECORD_COUNT=$3
OPERATION_COUNT=$4
COUNT_FILE="/mnt/io_uring/results/count.txt"
OUTPUT_DIR=""

SYSCOUNT_PID=""
CACHESTAT_PID=""
SAR_PID=""
SRV_PID=""

PORT="6379"
HOST="127.0.0.1"

trap "exxit" EXIT
trap "exxit" SIGTERM

#maintain how many times the script has run to track
if [ -e $COUNT_FILE ]; then
    count=$(cat ${COUNT_FILE})
else
    count=0
fi
((count++))
echo ${count} > ${COUNT_FILE}

#output dir for storing results of this invocation
OUTPUT_DIR="/mnt/io_uring/results/${count}-$(date)"

#check redis/dragonfly
if [ "$1" = 'r' ]; then
    SRV="$(which redis-server)"
elif [ "$1" = 'd' ]; then
    SRV="$(which dragonfly)"
fi

#check if record count and operation count are specified, note that both must be specified
#or none. if not specified, chenge to default value of 1 million
if [ $# -eq 4 ]; then
    sed -i -e "s/^recordcount=.*/recordcount=${RECORD_COUNT}/" ${WORKLOAD_DIR}/"${WORKLOAD_TYPE}"
    sed -i -e "s/^operationcount=.*/operationcount=${OPERATION_COUNT}/" ${WORKLOAD_DIR}/"${WORKLOAD_TYPE}"
else
    sed -i -e "s/^recordcount=.*/recordcount=1000000/" ${WORKLOAD_DIR}/"${WORKLOAD_TYPE}"
    sed -i -e "s/^operationcount=.*/operationcount=1000000/" ${WORKLOAD_DIR}/"${WORKLOAD_TYPE}"
fi

#start the selected server redis/dragonfly
${SRV} > "${OUTPUT_DIR}"/"${SRV}".log &
SRV_PID=$!

#run ycsb
$YCSC_SH load redis -s -P ${YCSB_BASE}/workloads/"${WORKLOAD_TYPE}" -p "redis.host=${HOST}" -p "redis.port=${PORT}" >> "${OUTPUT_DIR}"/ycsb-out.txt 2>> "${OUTPUT_DIR}"/ycsb-err.txt
$YCSC_SH run redis -s -P ${YCSB_BASE}/workloads/"${WORKLOAD_TYPE}" -p "redis.host=${HOST}" -p "redis.port=${PORT}" >> "${OUTPUT_DIR}"/ycsb-out.txt 2>> "${OUTPUT_DIR}"/ycsb-err.txt &

#wait for ycsb to setup maven
sleep 5

syscounts -L -p ${SRV_PID} >> "${OUTPUT_DIR}"/syscounts-out.txt 2>> "${OUTPUT_DIR}"/syscounts-err.txt &
SYSCOUNT_PID=$!

cachestat >> "${OUTPUT_DIR}"/cachestat-out.txt 2>> "${OUTPUT_DIR}"/cachestat-err.txt &
CACHESTAT_PID=$!

sar -B >> "${OUTPUT_DIR}"/sar-out.txt 2>> "${OUTPUT_DIR}"/sar-err.txt $
SAR_PID=$!


function exxit() {
    kill $SRV_PID
    kill $SYSCOUNT_PID
    kill $CACHESTAT_PID
    kill $SAR_PID
}



