#!/bin/bash

storages=($(jq -rM .storage[] /etc/pear/pear_monitor/config.json))
swap_size_GB=''
swap_path=''
maximum_storage=''

find_maximum_storage() {
   for dir in "${storages[@]}"; do
      if [ "${1}1" = "${dir}1" ]; then
         continue
      fi
      storage_size=$(df "${dir}" 2>/dev/null | awk 'NR==2 {print $2}')
      if [ -z "${Maximum_storage}" ]; then
         maximum_storage="${dir}"
         maximum_storage_size="${storage_size}"
      else
         if [ "${storage_size}" -gt "${maximum_storage_size}" ]; then
            maximum_storage="${dir}"
            maximum_storage_size="${storage_size}"
         fi
      fi
   done
   swap_path="${maximum_storage}/"
}

select_storage() {
   if [ ${#storages[@]} -eq "0" ]; then
      echo "Read storages from config.json failed"
      exit 1
   fi
   for dir in "${storages[@]}"; do
      if [ "$(df "${dir}" 2>/dev/null | awk 'NR==2' | wc -l)1" = "11" ] && [ "$(df "${dir}" 2>/dev/null | awk 'NR==2 {print $6}')1" = "/1" ]; then
         echo "${dir} is in system disk"
         if [ ${#storages[@]} -eq "1" ]; then
            swap_path="/"
            break
         elif [ ${#storages[@]} -gt 1 ]; then
            find_maximum_storage "${dir}"
            break
         fi
      fi
   done
   if [ -z "${swap_path}" ]; then
      swap_path="/"
   fi
}

swap_off() {
   old_swap_files=($(cat /proc/swaps | grep pear_swap | awk '{print $1}'))
   for old_swap_file in "${old_swap_files[@]}"; do
      swapoff "${old_swap_file}"
      echo "swapoff ${old_swap_file}"
      rm -f "${old_swap_file}"
      echo "remove ${old_swap_file}"
   done
}

swap_create() {
   flag=$(cat /proc/swaps | grep pear_swap | wc -l)
   if [ "${flag}" -eq "0" ]; then
      echo "no swap file found, create new one."
      select_storage
      available_size=$(($(df -P -k "${swap_path}" 2>/dev/null | awk 'NR==2 {print $4}')/ 1024 / 1024 - 10))
      if [ "${available_size}" -le "0" ]; then
         echo "no enough space to create swap file."
         exit 1
      fi
      if [ "${available_size}" -lt "${swap_size_GB}" ]; then

         swap_size_GB="${available_size}"
      fi
      cd ${swap_path}
      count=$((${swap_size_GB} * 1024 * 1024 * 1024 / 4096))
      dd if=/dev/zero of=pear_swap bs=4096 count=${count}
      chmod 0600 pear_swap
      mkswap pear_swap
      swapon "${swap_path}pear_swap"
      echo "create swap file ${swap_path}pear_swap success."

      # rm -f /tmp/fstab
      # cat /etc/fstab | grep -v pear_swap > /tmp/fstab
      # install -m 644 /tmp/fstab /etc/fstab
      # echo "${swap_path}pear_swap swap swap defaults,pri=10 0 0" >> /etc/fstab

      # num=`cat /etc/fstab |grep pear_swap |wc -l`
      # if [ "${num}" -lt "1" ];then
      #    echo /pear_swap swap swap defaults 0 0 >> /etc/fstab
      # fi

   elif [ "${flag}" -eq "1" ]; then
      echo "one swap file found, checking path and size."
      select_storage
      old_swap_file=$(cat /proc/swaps | grep pear_swap | awk '{print $1}')
      old_swap_size=$(($(ls -l ${old_swap_file} | awk '{print $5}') / 1024 / 1024 / 1024))
      if [ "$(df ${old_swap_file} | awk 'NR==2 {print $6}')1" = "$(df ${swap_path} | awk 'NR==2 {print $6}')1" ]; then
         available_size=$(($(df -P -k "${swap_path}" 2>/dev/null | awk 'NR==2 {print $4}') / 1024 / 1024 - 10 + ${old_swap_size}))
      else
         available_size=$(($(df -P -k "${swap_path}" 2>/dev/null | awk 'NR==2 {print $4}') / 1024 / 1024 - 10))
      fi
      if [ "${available_size}" -le "0" ]; then
         echo "no enough space to create swap file."
         exit 1
      fi
      if [ "${old_swap_file}1" != "${swap_path}pear_swap1" ]; then
         echo "swap file path is not correct, remove it and create new one."
         swapoff "${old_swap_file}"
         rm -f "${old_swap_file}"
         if [ "${available_size}" -lt "${swap_size_GB}" ]; then
            swap_size_GB="${available_size}"
         fi
         cd ${swap_path}
         count=$((${swap_size_GB} * 1024 * 1024 * 1024 / 4096))
         dd if=/dev/zero of=pear_swap bs=4096 count=${count}
         chmod 0600 pear_swap
         mkswap pear_swap
         swapon "${swap_path}pear_swap"
         echo "create swap file ${swap_path}pear_swap success."
      elif [ "${old_swap_size}" -ne "${swap_size_GB}" ] && [ "${old_swap_size}" -ne "${available_size}" ]; then
         echo "swap file size is not correct, remove it and create new one."
         swapoff "${old_swap_file}"
         rm -f "${old_swap_file}"
         if [ "${available_size}" -lt "${swap_size_GB}" ]; then
            swap_size_GB="${available_size}"
         fi
         cd ${swap_path}
         count=$((${swap_size_GB} * 1024 * 1024 * 1024 / 4096))
         dd if=/dev/zero of=pear_swap bs=4096 count=${count}
         chmod 0600 pear_swap
         mkswap pear_swap
         swapon "${swap_path}pear_swap"
         echo "create swap file ${swap_path}pear_swap success."
      else
         echo "swap file path and size is correct."
      fi

   else
      echo "more than one swap files found, remove all and create new one."
      swap_off
      select_storage
      available_size=$(($(df -P -k "${swap_path}" 2>/dev/null | awk 'NR==2 {print $4}') / 1024 / 1024 - 10))
      if [ "${available_size}" -le "0" ]; then
         echo "no enough space to create swap file."
         exit 1
      fi
      if [ "${available_size}" -lt "${swap_size_GB}" ]; then
         swap_size_GB="${available_size}"
      fi
      cd ${swap_path}
      count=$((${swap_size_GB} * 1024 * 1024 * 1024 / 4096))
      dd if=/dev/zero of=pear_swap bs=4096 count=${count}
      chmod 0600 pear_swap
      mkswap pear_swap
      swapon "${swap_path}pear_swap"
      echo "create swap file ${swap_path}pear_swap success."

   fi
   #swapoff /pear_swap
   #rm -rf /pear_swap
}

echo "swap_create.sh start."
case ${1} in
off)
   swap_off
   ;;
[0-9]*)
   swap_size_GB=${1}
   swap_create
   ;;
*)
   echo "Usage: swap_create.sh [off|size]"
   exit 1
   ;;
esac
echo "swap_create.sh finished."

exit 0
