#!/bin/bash

DATA_DISK_TYPE="xfs"
PART_ENABLED="FALSE"
MOUNT_ENABLED="FALSE"
DOCKER_NUMBER=1
PART_ONE_DISK_NAME=""

print_usage() {
echo "
Usage: sh part.sh [OPTION]   (chmod 777 part.sh)

  --part                 enable to part disks
  --mount                enable to mount
  --part_one             part only one disk
"
exit 1
}


check_one_param() {
  name=$1
  value=$2
  case ${name} in
    # docker_number)
    #   DOCKER_NUMBER=${value}
    #   ;;
    mount)
      MOUNT_ENABLED="TRUE"
      ;;
    part)
      PART_ENABLED="TRUE"
      ;;
    part_one)
      PART_ONE_DISK_NAME=${value}
      ;;
    help)
      print_usage
      exit 1
      ;;
  esac
}


PARAMS=$@
check_params() {
  for arg in ${PARAMS}; do
    param=${arg:2}
    param=${param//=/ }
    param=(${param})
    check_one_param ${param[0]} ${param[1]}
  done
}
check_params


check_permission() {
  if [[ `whoami` != 'root' ]]; then
    echo "requires root privileges to execute."
    echo "please run this script as root."
    exit 1
  fi 
}
check_permission


# such as sda
root_disk=""
get_root_disk() {
  root_disk_name=`df -hT | grep -e '/$' | awk '{print $1}' | awk -F/ '{print $3}'`
  disks=`lsblk -o NAME,TYPE | grep disk  | awk '{print $1}'`
  root_disk=${root_disk_name}
  for disk in ${disks[@]}; do
    if [[ ${root_disk_name:0:${#disk}} == ${disk} ]]; then
      root_disk=${disk}
      echo "get root disk: ${root_disk}"
      break
    fi
  done
}


# such as /dev/sda
root_disk_dev=""
get_root_disk_with_dev() {
  root_disk_name=`df -hT | grep -e '/$' | awk '{print $1}'`
  disks=`lsblk | grep disk | grep -v loop | awk '{system("echo /dev/" $1)}'`
  for disk in ${disks[@]}; do
    if [[ ${root_disk_name:0:${#disk}} == ${disk} ]]; then
      root_disk_dev=${disk}
      echo "get root disk dev: ${root_disk_dev}"
      break
    fi
  done
}


# such as /dev/sda
declare -a data_disks_with_dev 
get_data_disks_with_dev() {
  unset data_disks_with_dev
  disks=`lsblk | grep disk | grep -v loop | awk '{system("echo /dev/" $1)}'`
  for disk in ${disks[@]}; do
    # skip root disk
    if [[ ${root_disk_dev} == ${disk} ]]; then
      echo "skip root disk ${disk}"
      continue
    fi
    # check disk is valid
    output_result=`fdisk -l ${disk}`
    if [[ -z ${output_result} ]]; then
      error_result=`fdisk -l ${disk} 2>&1`
      echo "disk "${disk} " read error: ${error_result}"
      continue
    fi
    data_disks_with_dev[${#data_disks_with_dev[@]}]=${disk}
  done
}


# get total disk size
declare -i data_disks_number
declare -i data_disks_size
get_data_disks_size_and_number() {
  data_disks_number=${#data_disks_with_dev[@]}
  for disk in ${data_disks_with_dev[@]}; do 
    disk_size=`lsblk ${disk} -b -o SIZE | grep -m 1 -vi SIZE`
    disk_size=$((${disk_size} / 1024 / 1024 / 1024))
    data_disks_size=$((${data_disks_size} + ${disk_size}))
    echo "${disk} size: ${disk_size}G"
  done
  echo "total disk number: ${data_disks_number}, total size: ${data_disks_size}G"
}


declare -i disk_part_total_number
declare -i disk_part_number
declare -i disk_part_extra
get_disk_part_number_and_extra_and_total_number() {
  if [[ ${DOCKER_NUMBER} -eq 1 ]]; then
    disk_part_total_number=${data_disks_number}
    disk_part_number=1
    disk_part_extra=0
  elif [[ ${DOCKER_NUMBER} -lt ${data_disks_number} ]]; then
    disk_part_total_number=${data_disks_number}
    disk_part_number=1
    disk_part_extra=0
  elif [[ ${DOCKER_NUMBER} -gt 1 ]]; then
    disk_part_total_number=${DOCKER_NUMBER}
    disk_part_number=$((${DOCKER_NUMBER} / ${data_disks_number}))
    disk_part_extra=$((${DOCKER_NUMBER} % ${data_disks_number}))
  else
    echo "unexpected docker number, exit"
    exit 1
  fi
}


# asssume: each one of disks has the same size
disk_part_command=""
disk_part_real_number=0
get_disk_part_command_and_real_number() {
  disk=$1
  disk_size=`lsblk ${disk} -b -o SIZE | grep -m 1 -vi SIZE`
  disk_size=$((${disk_size} / 1024 / 1024 / 1024))
  echo "disk size is ${disk_size}G"
  # 
  disk_part_real_number=${disk_part_number}
  if [[ ${disk_part_extra} -gt 0 ]]; then
    disk_part_real_number=$((${disk_part_real_number} + 1))
    disk_part_extra=$((${disk_part_extra} - 1))
  fi
  part_size=$((${disk_size} / ${disk_part_real_number}))
  # 
  disk_part_command="parted --script ${disk} mklabel gpt "
  for k in `seq 0 $((${disk_part_real_number} - 1))`; do
    if [[ $k -eq 0 ]]; then
	    disk_part_command=${disk_part_command}"mkpart primary 100MiB $((${part_size}-1))GiB "
    else
      disk_part_command=${disk_part_command}"mkpart primary $((part_size*k))GiB $((part_size*(k+1)))GiB "
    fi
  done
}


# only support xfs
disk_format_command=""
get_disk_format_command() {
  disk=$1
  part_number=$2
  dev_name=${disk}${part_number}
  if [[ ${disk} =~ "nvme" ]]; then
    echo "its nvme storage"
    dev_name=${disk}p${part_number}
  fi
  disk_format_command="mkfs.xfs -f -l lazy-count=1 ${dev_name}"
}


# 
umount_ok="TRUE"
umount_by_disk() {
  disk=$1
  mount_points=`df | grep ${disk} | awk '{print $6}'`
  if [[ -z ${mount_points} ]]; then
    umount_ok="TRUE"
    return
  fi
  # 
  for mount_point in ${mount_points[@]}; do
    cmd="umount ${mount_point}"
    echo ${cmd}
    ${cmd} 2> temp
    if [[ -n ${temp} ]]; then
      echo "umount error: ${temp}"
    fi
    rm -f temp
  done
  # check again
  mount_points=`df | grep ${disk} | awk '{print $6}'`
  if [[ -n ${mount_points} ]]; then
    umount_ok="FALSE"
  else
    umount_ok="TRUE"
  fi
}


#
part_success=0
part_one_disk() {
  disk=$1
  # 
  get_disk_part_command_and_real_number ${disk}
  echo "${disk_part_command}"
  echo "disk real number: ${disk_part_real_number}"
  # 
  umount_by_disk ${disk}
  if [[ "1${umount_ok}" == "1FALSE" ]]; then
    echo ${disk} "is busy, could not be umounted "
    part_success=0
    return
  fi
  # parted
  rm -f /tmp/part_error.txt
  rm -f /tmp/part_info.txt
  ${disk_part_command} 2> /tmp/part_error.txt  1> /tmp/part_info.txt
  cmd_error=`cat /tmp/part_error.txt`
  if [[ -n  ${cmd_error} ]]; then
    echo ${cmd_error}
    part_success=0
    return
  fi
  
  sleep 5
  
  # format 
  for i in `seq 1 ${disk_part_real_number}`; do
    rm -f /tmp/format_error.txt
    rm -f /tmp/format_info.txt
    get_disk_format_command ${disk} ${i}
    echo "${disk_format_command}"
    ${disk_format_command} 2>/tmp/format_error.txt 1>/tmp/format_info.txt
    cmd_error=`cat /tmp/format_error.txt`
    if [[ -n  ${cmd_error} ]]; then
      echo ${cmd_error}
      continue
    fi
  done
  part_success=1
}


if [ "1${PART_ONE_DISK_NAME}" != "1" ]; then
  echo "part begin..."
  get_root_disk_with_dev
  get_data_disks_with_dev
  get_data_disks_size_and_number
  get_disk_part_number_and_extra_and_total_number
  part_one_disk ${PART_ONE_DISK_NAME}
  if [[ ${part_success} -eq 0 ]]; then
    echo "part failed, disk: ${PART_ONE_DISK_NAME}"
    echo "error"
  fi
  exit 1
fi

#
part_all_disks() {
  echo "part begin..."
  get_root_disk_with_dev
  get_data_disks_with_dev
  get_data_disks_size_and_number
  get_disk_part_number_and_extra_and_total_number
  for disk in ${data_disks_with_dev[@]}; do
    part_one_disk ${disk}
    if [[ ${part_success} -eq 0 ]]; then
      echo "part failed, disk: ${disk}"
      echo "error"
      exit 1
    fi
  done
  echo "part done"
}


# part disks
if [ "1${PART_ENABLED}" == "1TRUE" ]; then
  part_all_disks
else
  echo "skip part disks"
fi


# create dirctories for mounting part devices
mkdir_part_device_names() {
  rm -rf /sata*
  for i in `seq 0 $((disk_part_total_number-1))`; do
    sata_name="/sata${i}"
    cmd="mkdir -p ${sata_name}"
    echo ${cmd}
    ${cmd}
  done
}


# umount part devices by prefix '/sata*'
umount_sata_n() {
  for i in `seq 0 $((disk_part_total_number-1))`; do
    umount_command="umount /sata${i}"
    echo ${umount_command}
    result=$(${umount_command} 2>&1)
    while [[ -z ${result} ]]; do
      sleep 2
      result=$(${umount_command} 2>&1)
    done
  done
}


# generate mount command
base_mount_cmd="mount -o rw,noatime,nodiratime"
base_remount_cmd="mount -o rw,remount,noatime,nodiratime"
get_base_mount_command() {
  if [[ ${DATA_DISK_TYPE} == "exfat" ]]; then
    echo "exfat..."
  elif [[ ${DATA_DISK_TYPE} == "xfs" ]]; then
    echo "xfs..."
    base_mount_cmd="${base_mount_cmd},noiversion,noquota"
    base_remount_cmd="${base_remount_cmd},noiversion,attr2,inode64"
  elif [[ ${DATA_DISK_TYPE} == "ext4" ]]; then
    echo "ext4..."
    base_mount_cmd="${base_mount_cmd},noiversion,noquota,nobarrier"
    base_remount_cmd="${base_remount_cmd},noiversion,noquota,nobarrier"
  else
    echo "data disk type unknown..."
    exit 1
  fi
}


declare -a part_devices
get_part_devices() {
  echo "getting part devices..."
  get_root_disk
  part_device_names=`lsblk -o PARTUUID,KNAME,FSTYPE,SIZE,TYPE,MOUNTPOINT | grep part | grep -v ${root_disk} | grep -v sata | awk '{system("echo /dev/" $2)}'`
  for part_device in ${part_device_names[@]}; do
    # check fstype
    part_fstype=`lsblk -o FSTYPE ${part_device} | grep -v FSTYPE`
    if [[ "1${part_fstype}" != "1${DATA_DISK_TYPE}" ]]; then
      echo "${part_device}, ${part_fstype} not expected, skip  "
      continue
    fi
    # do not check size(size is automatically calculated)
    part_devices[${#part_devices[@]}]=${part_device}
  done
}


run_mount_part_device_command() {
  part_device_command=$@
  split_temp=(${part_device_command})
  sata_name=${split_temp[$((${#split_temp}-1))]}
  echo ${part_device_command}
  # echo ${sata_name}
  if [[ "${sata_name:0:5}" == "/sata" ]]; then
    # 
    if [[ ! -d ${sata_name} ]]; then
      mkdir -p ${sata_name}
    fi
    # 
    if [[ -f "temp" ]]; then
      rm -f temp
    fi
    ${part_device_command} 2> temp
    result=`cat temp`
    if [[ -n ${result} ]]; then
      echo "mount failed, error: ${result}"
    fi
    rm -f temp
  fi
}


# 
mount_history_file="/root/pear/pear_remount.sh"
mount_part_device() {
  part_device=$1
  part_device_uuid=$2
  sata_list="/sata*"
  for sata in ${sata_list[@]}; do  
    if mountpoint -q ${sata}; then
      # echo ${sata} "has been mounted"
      continue
    fi
    #
    if lsblk | grep -w ${sata}; then
      echo "has mounted by lsblk, then skip ${sata}"
      continue
    fi  
    
    echo "get idle sata point : " ${sata}
    # 
    mount_command="${base_mount_cmd} PARTUUID=${part_device_uuid} ${sata}"
    # rm -rf ${sata}/*
    run_mount_part_device_command ${mount_command}
    echo ${mount_command} >> ${mount_history_file}
    break
  done
}


mount_one_part_device() {
  part_device=$1
  part_device_uuid=`lsblk -o PARTUUID ${part_device} | grep -v PARTUUID`
  part_device_remount_command=`cat ${mount_history_file} | grep ${part_device_uuid}`
  # do mount or remount according to ${mount_history_file}
  if [[ -n  ${part_device_remount_command} ]]; then
    echo "remount ${part_device}..."
    run_mount_part_device_command ${part_device_remount_command}
  else
    echo "mount ${part_device}..."
    mount_part_device ${part_device} ${part_device_uuid} 
  fi
}


mount_all_part_devices() {
  echo "mount devices begin..."
  #
  get_root_disk_with_dev
  get_data_disks_with_dev
  get_data_disks_size_and_number
  get_disk_part_number_and_extra_and_total_number
  get_base_mount_command
  if [[ ! -f ${mount_history_file} ]]; then
    lsblk -o PARTUUID,MOUNTPOINT | grep sata | awk '{print "'"$base_mount_cmd"'" " PARTUUID=" $1 " " $2}' > ${mount_history_file}
    chmod +x ${mount_history_file}
  fi
  # unmount all
  umount_sata_n
  mkdir_part_device_names
  # do mount operation
  get_part_devices
  for part in ${part_devices[@]}; do
    mount_one_part_device ${part}
  done
  echo "mount devices done"
}


# mount parts
if [[ "1${MOUNT_ENABLED}" == "1TRUE" ]]; then
  # 清空
  # cat /dev/null > ${mount_history_file}
  mount_all_part_devices
else
  echo "skip mount part devices"
fi


# 
if [[ "1${PART_ENABLED}" != "1TRUE" && "1${MOUNT_ENABLED}" != "1TRUE" ]]; then
  echo "didn't do anything"
  print_usage
  exit 1
else
  echo "done" > /tmp/part_done.txt
fi
