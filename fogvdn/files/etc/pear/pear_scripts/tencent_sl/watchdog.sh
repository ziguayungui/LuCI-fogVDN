#!/bin/bash

INTERVAL_SECONDS=1800
LOG_PATH=/tmp/watchdog.log

error_happened=0
step_into_number=0

check_if_lego_server_fault_happened() {
  ps_result=`ps -ef | grep lego_server | grep -v grep | grep -v watchdog`
  if [[ -z ${ps_result} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] lego_server fault" >> ${LOG_PATH}
    error_happened=1
  fi
}

check_if_ppp_fault_happened() {
  ppp_list=`ifconfig | grep ppp | grep mtu | awk -F: '{print $1}'`
  ppp_array=(${ppp_list})
  for ppp in ${ppp_array[@]}; do
    ping_result=`ping -c 4 -I ${ppp} qq.com`
    has_error=`echo ${ping_result} | grep "100% packet loss"`
    if [[ -z ${has_error} ]]; then
      datetime=`date "+%Y-%m-%d %H:%M:%S"`
      echo "${datetime} [ERROR] ${ppp} fault" >> ${LOG_PATH}
      ifconfig ${ppp} >> ${LOG_PATH}
      # do not mark this flag error_happened so far.
      # because, we don't have 
      # error_happened=1
    fi
  done
}

check_if_pear_monitor_fault_happened() {
  ps_result=`ps -ef | grep pear_monitor | grep -v grep`
  if [[ -z ${ps_result} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] pear_monitor fault" >> ${LOG_PATH}
    error_happened=1
  fi
}

check_if_error_happened() {
  check_if_lego_server_fault_happened
  check_if_ppp_fault_happened
  check_if_pear_monitor_fault_happened
  if [[ ${error_happened} -ne 0 ]]; then
    # when detected fault happened, 
    # restart monitor(monitor will do something to recover it)
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [INFO ] error happened, restart pear monitor" >> ${LOG_PATH}
    /etc/init.d/xc_cdn.sh stop
    docker rm -f $(docker ps -a -q)
    /etc/init.d/xc_cdn.sh start
	# reset variable
    error_happened=0
  fi
} 

while :
do
  # the first time must be called by /etc/init.d/xc_cdn.sh start
  # so...
  if [[ ${step_into_number} -ne 0 ]]; then
    check_if_error_happened
    step_into_number=$(($step_into_number + 1))
  fi
  sleep ${INTERVAL_SECONDS}
done
