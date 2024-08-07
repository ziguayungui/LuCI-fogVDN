#!/bin/bash

echo "pear_on_minute_check"

function check_lo()
{
     # ip address add 127.0.0.1/8  scope host  dev  lo 
     # ifconfig lo 127.0.0.1 netmask 255.0.0.0 up
     # https://stackoverflow.com/questions/8529181/which-terminal-command-to-get-just-ip-address-and-nothing-else
     
     # ifconfig lo 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'
     local_ip=`ifconfig lo | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`
     if [ "i$local_ip" == "i" ]
     then 
          echo "ip is null"
          local_ip=`ip addr show lo | grep "host lo" | grep -Po 'inet \K[\d.]+'`
     fi 

     if [ "i$local_ip" == "i" ]
     then 
          echo "ip is null"
          local_ip=`ifconfig lo | awk '/t addr:/{gsub(/.*:/,"",$2);print$2}'`
     fi 
     if [ "i$local_ip" == "i" ]
     then 
          echo "ip is null"
          local_ip=`ip -f inet addr show lo | grep -Po 'inet \K[\d.]+'`
     fi
     
     if [ "i$local_ip" != "i127.0.0.1" ]
     then
          # record lo address abnormal
          echo `date +%s` "lo address abnormal"  >> /root/pear/log/checkoneminute.txt
          ifconfig lo 127.0.0.1 netmask 255.0.0.0 up
     fi 
}

function check_dns()
{
   #   NUM1=`cat /etc/hosts | grep "122.152.200.206" |wc -l`
   #   NUM2=`cat /etc/hosts | grep "122.152.200.206 api.webrtc.win" |wc -l`
     
   #   if [ "${NUM1}" -gt "1" ] || [ "${NUM2}" -lt "1" ];then
   #        grep -v "122.152.200.206" /etc/hosts > /tmp/hosts.tmp
   #        mv /tmp/hosts.tmp /etc/hosts
   #        echo "122.152.200.206 api.webrtc.win" >> /etc/hosts
   #   fi

      DNS_NAMES=("api.webrtc.win"  
               "download.openfogos.com"
               "updatetencent.webrtc.win"
               "docker.webrtc.win"
               "nmsapi.webrtc.win")
      
      IP=("122.152.200.206 111.231.101.54"
         "49.234.47.74 118.25.20.200"
         "49.234.47.74 118.25.20.200"
         "49.234.47.74 118.25.20.200"
         "118.25.127.105 106.54.19.136")

      for i in "${!DNS_NAMES[@]}"
      do
         NUM=`cat /etc/hosts | grep "${DNS_NAMES[$i]}" |wc -l`
         if [ "${NUM}" -gt "2" ];then
            grep -v "${DNS_NAMES[$i]}" /etc/hosts > /tmp/hosts.tmp
            mv /tmp/hosts.tmp /etc/hosts
         fi

         IFS=' ' read -r -a single_ips <<< "${IP[$i]}"
         for single_ip in "${single_ips[@]}"
         do
            NUM=`cat /etc/hosts | grep "${single_ip} ${DNS_NAMES[$i]}" |wc -l`
            if [ "${NUM}" -lt "1" ];then
               echo "${single_ip} ${DNS_NAMES[$i]}" >> /etc/hosts
            fi
         done
      done

      # NUM=`cat /etc/hosts | grep "122.152.200.206 ${DNS_NAME}" |wc -l`

      # if [ "${NUM}" -lt "1" ];then
      #    echo "122.152.200.206 ${DNS1_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "111.231.101.54 ${DNS1_NAME}" |wc -l`

      # if [ "${NUM}" -lt "1" ];then
      #    echo "111.231.101.54 ${DNS1_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "49.234.47.74 ${DNS2_NAME}" |wc -l`

      # if [ "${NUM}" -lt "1" ];then
      #    echo "49.234.47.74 ${DNS2_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "118.25.20.200 ${DNS2_NAME}" |wc -l`

      # if [ "${NUM}" -lt "1" ];then
      #    echo "118.25.20.200 ${DNS2_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "49.234.47.74 ${DNS3_NAME}" |wc -l`
      
      # if [ "${NUM}" -lt "1" ];then
      #    echo "49.234.47.74 ${DNS3_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "118.25.20.200 ${DNS3_NAME}" |wc -l`
      
      # if [ "${NUM}" -lt "1" ];then
      #    echo "118.25.20.200 ${DNS3_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "49.234.47.74 ${DNS4_NAME}" |wc -l`
      
      # if [ "${NUM}" -lt "1" ];then
      #    echo "49.234.47.74 ${DNS4_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "118.25.20.200 ${DNS4_NAME}" |wc -l`
      
      # if [ "${NUM}" -lt "1" ];then
      #    echo "118.25.20.200 ${DNS4_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "118.25.127.105 ${DNS5_NAME}" |wc -l`
      
      # if [ "${NUM}" -lt "1" ];then
      #    echo "118.25.127.105 ${DNS5_NAME}" >> /etc/hosts
      # fi

      # NUM=`cat /etc/hosts | grep "106.54.19.136 ${DNS5_NAME}" |wc -l`
      
      # if [ "${NUM}" -lt "1" ];then
      #    echo "106.54.19.136 ${DNS5_NAME}" >> /etc/hosts
      # fi

      NUM=`cat /etc/resolv.conf | grep 119.29.29.29 |wc -l`
      
      if [ "${NUM}" -lt "1" ];then
         echo nameserver 119.29.29.29 >> /etc/resolv.conf
      fi

      NUM=`cat /etc/resolv.conf | grep 114.114.114.114 |wc -l`
      
      if [ "${NUM}" -lt "1" ];then
         echo nameserver 114.114.114.114 >> /etc/resolv.conf
      fi
}

function pear_on_minute_check()
{
     check_lo
     check_dns
}

while true :
do
     pear_on_minute_check 
     sleep 60
done 
