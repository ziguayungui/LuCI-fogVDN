#!/bin/bash
if [[ -f /root/pear/pear_remount.sh ]]; then
  echo "mount partuuid and sata "
  records=`cat /root/pear/pear_remount.sh | wc -l`
  /root/pear/pear_remount.sh
else
  echo "mount_on_reboot fail, file pear_remount.sh not exist "
fi

mrecords=`mount | grep sata | wc -l`
if [[ ${mrecords}  == ${records} ]]; then
  echo "mount ok"
else
  echo "mount records not enough "
fi
