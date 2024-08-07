#!/bin/bash

UPDATE_AT="00" # 00:00 - 00:59
UPDATE_URL="http://47.52.153.245:9394/scan"
UPDATE_OK="TRUE"
CP_NAME="qiniuyun_video"
LOG_NAME="logs/beidou_agent.log"
USE_LSBLK="FALSE"
RETRY_TIMES=3
INTERVAL_SECONDS=60
UUID=""


declare -a data_disks 
get_data_disks() {
  disks=`lsblk  | grep disk | grep -v loop | awk '{system("echo /dev/" $1)}'`
  disks=(${disks[@]})
  for part in ${disks[@]}; do
    output_result=`fdisk -l ${part}`
    if [[ -z ${output_result} ]]; then
      echo "disk "${part} "read error"
      continue
    fi
    # echo ${part}
    data_disks[${#data_disks[@]}]=${part}
  done
}


declare -a data_disk_mount_points
get_data_disk_mount_points() {
  get_data_disks
  root_file_system_name=`df -hT | grep ext4 | grep -e '/$' | awk '{print $1}'`
  for part in ${data_disks[@]}; do
    length=${#part}
    if [ ${root_file_system_name:0:${length}} != ${part} ]; then
      mount_points=`df | grep ${part} | awk '{print $6}'`
      # echo ${mount_points}
      data_disk_mount_points[${#data_disk_mount_points[@]}]=${mount_points}
    fi
  done
}


get_data_disk_mount_points_2() {
  for path in `ls /`; do
    if [ "1${path:0:4}" == "1sata" ]; then
      path="/${path}"
      data_disk_mount_points[${#data_disk_mount_points[@]}]=${path}
    fi
  done
}


declare -a cp_version_logs
declare -a sata_numbers
get_cp_version_logs() {
  for mount_point in ${data_disk_mount_points[@]}; do
    path="${mount_point}/openfogos"
    for cp_path in `ls ${path}`; do
      if [ ${cp_path} == ${CP_NAME} ]; then
        path=${path}/${CP_NAME}/${LOG_NAME} 
        cp_version_logs[${#cp_version_logs[@]}]=${path}
        num=${mount_point:5}
        sata_numbers[${#sata_numbers[@]}]=${num}
        # echo "${path} ${num}"
        break
      fi
    done
  done
}


declare -a cp_version_info
get_cp_version_info() {
  for ((i=0; i < ${#cp_version_logs[@]}; i++)); do
  # for path in ${cp_version_logs[@]}; do
    # mac,version
    info=`tail -1 ${cp_version_logs[${i}]} | awk '{printf("%s,%s",$4,$5)}'`
    # number
    info="${info},${sata_numbers[${i}]}"
    # echo ${info}
    cp_version_info[${#cp_version_info[@]}]=${info}
  done
}


get_pcdn_node_uuid() {
  UUID=`cat /proc/sys/kernel/random/uuid` 
  UUID="${UUID:0:9}p${UUID:10}"
  UUID="${UUID:0:14}e${UUID:15}"
  UUID="${UUID:0:19}a${UUID:20}"
  UUID="${UUID:0:24}r${UUID:25}" 
  # echo ${UUID}
}


upload_cp_version_info() {
  current_datetime=$1
  post_data=""
  for info in ${cp_version_info[@]}; do
    if [[ -z "${post_data}" ]]; then
      post_data="${info}"
    else
      post_data="${post_data};${info}"
    fi
  done
  if [[ -n "${post_data}" ]]; then 
    post_command="curl -sS -X POST -H time:${current_datetime} -H uuid:${UUID} --data ${post_data} ${UPDATE_URL}"
    # echo ${post_command}
    ${post_command} 2>/tmp/scan_error.log 1>/tmp/scan_result.log
    error_text=`cat /tmp/scan_error.log`
    # echo ${error_text}
    if [ -n "${error_text}" ]; then
      echo "post failed, error: ${error_text}"
      UPDATE_OK="FALSE"
    fi
  fi
}


retry_times=0
upload_version_info() {
  current_unix_time=`date "+%s"`
  current_time=`date "+%H"`
  update_list=(${UPDATE_AT})
  for update_time in ${update_list[@]}; do
    if [[ "1${current_time}" == "1${update_time}" ]]; then
      echo "time up ${current_time}, start uploading..."
      if [[ "1${USE_LSBLK}" == "1TRUE" ]]; then
        get_data_disk_mount_points
      else
        get_data_disk_mount_points_2
      fi
      get_cp_version_logs
      get_pcdn_node_uuid
      get_cp_version_info
      upload_cp_version_info ${current_unix_time}
      if [[ "1${UPDATE_OK}" == "1FALSE" ]]; then
        retry_times=${RETRY_TIMES}
      fi
      break
    fi
  done
  # upload again if failed
  if [[ ${retry_times} -gt 0 ]]; then
    echo "upload failed, try ${retry_times} times again..."
    upload_cp_version_info ${current_unix_time}
    retry_times=$((${retry_times} - 1))
  fi
}


while :
do
  scan_lego_server_crash
  sleep ${INTERVAL_SECONDS}
done


