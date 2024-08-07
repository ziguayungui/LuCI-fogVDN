#!/bin/bash

sleep 30

check_tools_status() {

    system=`cat /etc/issue |grep Ubuntu |wc -l`

    if [[ -z ${system} ]]; then
        yum update
    else
        apt update
    fi

    #check gcc-12
    exist=`whereis gcc-12 | awk '{print $2}'`

    if [[ -z ${exist} ]]; then
       if [[ -z ${system} ]]; then
          yum install gcc-12 -y
       else
          apt-get install gcc-12 -y
       fi
    fi

    #check dracut
    exist=`whereis dracut | awk '{print $2}'`

    if [[ -z ${exist} ]]; then
       if [[ -z ${system} ]]; then
          yum install dracut -y
       else
          apt-get install dracut -y
       fi
    fi

    #check initramfs-tools
    exist=`whereis initramfs-tools | awk '{print $2}'`

    if [[ -z ${exist} ]]; then
       if [[ -z ${system} ]]; then
          yum install initramfs-tools -y
       else
          apt-get install initramfs-tools -y
       fi
    fi
}


nic_driver_compilation()
{
	cd /root/

        if [ ! -f "/root/r8125-9.012.03.tar.bz2" ];then
           echo "tar not exist ,download now..." >> /tmp/install.log
           wget http://download.openfogos.com/r8125-9.012.03.tar.bz2
        fi
   
        md5check=`md5sum /root/r8125-9.012.03.tar.bz2 |grep 59c50068f6536327a9200e08acf94866 |wc -l`       
       
        if [ ${md5check} -eq 0 ]; then
           rm -rf /root/r8125-9.012.03.tar.bz2
        else
           tar -jxvf r8125-9.012.03.tar.bz2
           sleep 3
           cd /root/r8125-9.012.03/
           sed -i 's/ENABLE_MULTIPLE_TX_QUEUE = n/ENABLE_MULTIPLE_TX_QUEUE = y/g' src/Makefile
           sed -i 's/ENABLE_RSS_SUPPORT = n/ENABLE_RSS_SUPPORT = y/g' src/Makefile
           sed -i 's/CONFIG_ASPM = y/CONFIG_ASPM = n/g' src/Makefile
           cd /root/r8125-9.012.03/src
           make clean && make && make install 	   
	fi
}

nic_driver_loading()
{
	system_check=`cat /etc/issue |grep Ubuntu |wc -l`
	kernel_version=`uname -r`
	echo ${kernel_version} >> /tmp/install.log
	
	driver_already=` ls -l /usr/lib/modules/${kernel_version}/kernel/drivers/net/ethernet/realtek/r8125.ko |wc -l`
        echo "driver_already = ${driver_already}" >> /tmp/install.log
        if [ ${driver_already} -eq 1 ];then
           echo "The driver is compiled~" >> /tmp/install.log
	   rmmod r8169
           mv /usr/lib/modules/${kernel_version}/kernel/drivers/net/ethernet/realtek/r8169.ko   /usr/lib/modules/${kernel_version}/kernel/drivers/net/ethernet/realtek/r8169.ko.bak        
           insmod /usr/lib/modules/${kernel_version}/kernel/drivers/net/ethernet/realtek/r8125.ko

	   cd /lib/modules/${kernel_version}
	   depmod -a
	   dracut --force
	   update-initramfs -u	   

           if [[ -z ${system_check} ]]; then
		systemctl restart network.service
           else
	        systemctl restart NetworkManager.service
           fi

	   nohup /etc/router/scripts/start_wan.sh >/dev/null 2>&1 &
        fi
}

while true :
do
   lspci |grep RTL8125 >/dev/null
   if [ $? -eq 0 ]; then
	   driver_exist=`lsmod |grep r8125 |wc -l`
      kernel_version=$(uname -r | sed 's/-/./g' | sed 's/[^0-9.]*//g' | sed 's/\.\+/\./g')
      higher_version=$(echo -e "${kernel_version}\n6.4" | sort -V | tail -n 1)
      if [ "1${kernel_version}" = "1${higher_version}" ]; then
         echo "The kernel version is too high" >> /tmp/install.log
         break
    	elif [ ${driver_exist} -eq 1 ]; then
	      echo "The driver is loaded" >> /tmp/install.log
	      break
	   else
	      check_tools_status	   
    	   nic_driver_compilation
    	   nic_driver_loading
	      sleep 1800
	   fi
   else 
	   echo "Not support r8125.ko!" >> /tmp/install.log
	   break
   fi
done

exit 0
