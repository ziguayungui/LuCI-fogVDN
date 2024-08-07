#!/bin/bash
# Pear Limited


function wait_disk_ok()
{
  SLEEP_TIME=3
  RECORD_LOG="/root/pear/log/pear_init.log"
  for i in `seq 5`
  do
    DISK_SIZES=`lsblk  | grep disk | grep -v loop | grep T | awk '{print $4}' | sort | uniq`
    number=0
    if [[ -z ${DISK_SIZES} ]]; then
      echo "no greater 1T data disk "
      sleep ${SLEEP_TIME}
    else
      for disk_size  in ${DISK_SIZES[@]}
      do
        number=`lsblk  | grep disk | grep -v loop | grep ${disk_size} | wc -l`
        echo `date +'%Y-%m-%d %H:%M:%S'`  disk ${number} detect  >>  ${RECORD_LOG}
        if [[ ${number} -gt 5 ]]; then
            echo "find more than 5 data disks, so continue ..."
            sleep ${SLEEP_TIME}
            break
        fi
      done 
    fi
    if [[ ${number} -gt 5 ]]; then
      echo "find more than 5 data disks, so continue ..."
      sleep ${SLEEP_TIME}
      break
    fi
    sleep ${SLEEP_TIME}
  done 
}
wait_disk_ok