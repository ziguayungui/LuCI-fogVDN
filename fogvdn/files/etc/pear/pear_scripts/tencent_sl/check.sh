#!/bin/bash

INTERVAL=60

check_dockerd_is_running() {
  psdockerd=`ps -ef | grep dockerd | grep -v grep`
  if [[ -z ${psdockerd} ]]; then
    service docker start
  fi
}

check_local_timezone() {
  dt=`date "+%H:%M" | grep "00:00"`
  if [[ -n ${dt} ]]; then
    # check environment
    exist=`whereis ntpdate | awk '{print $2}'`
    if [[ -z ${exist} ]]; then
      apt-get install ntpdate -y
    fi
    # do sync time
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    ntpdate cn.pool.ntp.org
    hwclock --systohc
  fi
}

while :
do
  check_dockerd_is_running
  sleep ${INTERVAL}
done
