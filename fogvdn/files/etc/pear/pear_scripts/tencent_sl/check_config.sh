#!/bin/bash

#
DOCKER_NUMBER=1
NODE_NUMBER=1
DISK_NUMBER=10
#
PLATFORM=$1
#
INSTALL_PATH=
MAC_CONFIG_PATH=${INSTALL_PATH}/etc/pear/pear_monitor/mac.conf
MAC_CONFIG_BACKUP_PATH=${INSTALL_PATH}/etc/pear/pear_monitor/.mac.conf.bak
NIC_CONFIG_PATH=${INSTALL_PATH}/etc/pear/pear_monitor/nic.conf
NIC_CONFIG_BACKUP_PATH=${INSTALL_PATH}/etc/pear/pear_monitor/.nic.conf.bak
DISK_CONFIG_PATH=${INSTALL_PATH}/etc/pear/pear_monitor/dev.conf
DISK_CONFIG_BACKUP_PATH=${INSTALL_PATH}/etc/pear/pear_monitor/.dev.conf.bak
PLATFORM_CONFIG_PATH=${INSTALL_PATH}/etc/pear/pear_docker/docker_platform.conf
LOG_PATH=/tmp/check_config.log

sata_fault=1
check_if_sata_fault() {
  sata=$1
  sata_fault=0
  # method 1
  ls_result=`ls ${sata} | grep error`
  if [[ -n ${ls_result} ]]; then
    sata_fault=1
    echo "${sata} has error: ${ls_result}"
    return
  fi
  # method 2
  lsblk_result=`lsblk | grep ${sata}`
  if [[ -z ${lsblk_result} ]]; then
    sata_fault=2
    echo "${sata} has error: lsblk not found"
    return
  fi
  # method 3
  df_h_result=`df -h | grep ${sata}`
  if [[ -z ${df_h_result} ]]; then
    sata_fault=3
    echo "${sata} has error: df -h not found"
    return
  fi
}

check_disk_config() {
  # 
  if [[ ! -f ${DISK_CONFIG_BACKUP_PATH} ]];then
    cp ${DISK_CONFIG_PATH} ${DISK_CONFIG_BACKUP_PATH}
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [INFO ] backup ${DISK_CONFIG_PATH} to ${DISK_CONFIG_BACKUP_PATH}" >> ${LOG_PATH}
  fi
  
  # get configured sata
  sata_list=`cat ${DISK_CONFIG_PATH} | sed 's/,/ /g'`
  sata_array_conf=(${sata_list})

  # get mount sata
  sata_list="/sata*"
  sata_array_root=(${sata_list})

  # check fault sata 
  declare -a sata_array_ok
  for i in $(seq 0 $((${#sata_array_conf[@]} - 1))); do
    echo "checking ${sata_array_conf[$i]}"
    check_if_sata_fault ${sata_array_conf[$i]}
    if [[ ${sata_fault} -ne 0 ]]; then
      datetime=`date "+%Y-%m-%d %H:%M:%S"`
      echo "${datetime} [ERROR] configured ${sata_array_conf[$i]} fault(${sata_fault})" >> ${LOG_PATH}
    else
      sata_array_ok[${#sata_array_ok[@]}]=${sata_array_conf[$i]}
    fi
  done

  # check if nothing wrong, return if ok
  if [[ ${#sata_array_ok[@]} -eq ${#sata_array_conf[@]} ]]; then
    # nothing went wrong
    if [[ ${#sata_array_conf[@]} -ge ${DISK_NUMBER} ]]; then
      # confirm if run expected disk number
      datetime=`date "+%Y-%m-%d %H:%M:%S"`
      echo "${datetime} [INFO ] running in expected sata number(ok)" >> ${LOG_PATH}
      return
    elif [[ ${#sata_array_conf[@]} -eq ${#sata_array_root[@]} ]]; then
      # confirm if ran out all satas
      datetime=`date "+%Y-%m-%d %H:%M:%S"`
      echo "${datetime} [INFO ] running out of sata(ok), no remaining sata left" >> ${LOG_PATH}
      return
    fi
    # not enough configured sata number
    # but do not handle it here
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [INFO ] nothing went wrong, but running in unexpected sata number, ignore" >> ${LOG_PATH}
    return
  fi

  # something wrong happened
  # number=${#sata_array_ok[@]}
  # for root_sata in ${sata_array_root[@]}; do
  #   if [[ ${number} -ge ${DISK_NUMBER} ]]; then
  #     break
  #   fi
  #   # check if in config
  #   configured=0
  #   for conf_sata in ${sata_array_conf[@]}; do
  #     if [[ ${root_sata} == ${conf_sata} ]]; then
  #       configured=1
  #       break
  #     fi
  #   done
  #   # not in sata_array_conf
  #   if [[ ${configured} -eq 0 ]]; then
  #     # check if healthy
  #     check_if_sata_fault ${root_sata}
  #     datetime=`date "+%Y-%m-%d %H:%M:%S"`
  #     if [[ ${sata_fault} -ne 0 ]]; then
  #       echo "${datetime} [ERROR] failed to put ${root_sata} into config, fault number(${sata_fault})" >> ${LOG_PATH}
  #     else
  #       sata_array_ok[${#sata_array_ok[@]}]=${root_sata}
  #       echo "${datetime} [INFO ] put ${root_sata} into config" >> ${LOG_PATH}
  #     fi
  #   fi
  # done

  # 
  content=""
  for sata in ${sata_array_ok[@]}; do
    if [[ -z ${content} ]]; then
      content="${sata}"
    else
      content="${content},${sata}"
    fi
  done

  # 
  if [[ -z ${content} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [FATAL] no sata is available" >> ${LOG_PATH}
    exit 1
  fi
  echo ${content} > ${DISK_CONFIG_PATH}
}

declare -a ppp_array
check_nic_config() {
  #
  ppp_list=`ifconfig | grep ppp | grep mtu | awk -F: '{print $1}'`
  ppp_array=(${ppp_list})
  content=""
  for ((i = 0; i < ${#ppp_array[@]}; i++)); do
    ppp=${ppp_array[$i]}
    ping_result=`ping -f -c 4 -I ${ppp} qq.com`
    has_error=`echo ${ping_result} | grep "100% packet loss"`
    if [[ -n ${has_error} ]]; then
      datetime=`date "+%Y-%m-%d %H:%M:%S"`
      echo "${datetime} [ERROR] ${ppp} fault" >> ${LOG_PATH}
      continue
    fi
    #
    if [[ -z ${content} ]]; then
      content="${ppp}"
    else
      content="${content},${ppp}"
    fi
  done
  
  if [[ -z ${content} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [FATAL] no nic is available" >> ${LOG_PATH}
    exit 1
  fi
  echo ${content} > ${NIC_CONFIG_PATH}
}

check_docker_platform_config() {
  echo ${PLATFORM} > ${PLATFORM_CONFIG_PATH}
}

#
datetime=`date "+%Y-%m-%d %H:%M:%S"`
echo "${datetime} [INFO ] start checking config" >> ${LOG_PATH}

# check disk if some sata fault
check_disk_config

# check ppp (only ppp(s) are available)
check_nic_config

# not important config items, but pear_monitor needs it.
check_docker_platform_config

#
datetime=`date "+%Y-%m-%d %H:%M:%S"`
echo "${datetime} [INFO ] finish checking config" >> ${LOG_PATH}
