#!/bin/bash
  
echo "pear_ten_minutes_check"
# set -x
function restart_ppp()
{
     for index in `seq 0 99` ;
     do
          ppp_index=$(( index + 1 ))
          echo $index  " : " ${ppp_index}
          if  ping -I ppp${ppp_index} -c 4 -w 6 qq.com ;
          then
               echo "ping successful, no need restart " ppp${ppp_index}
          else
               echo "ping failed, restart " ppp${ppp_index}
               pid=$(ps aux | grep -w /etc/ppp/options.prfile${index} | grep -v grep  | awk '{print $2}')
               kill -9 ${pid}
               sleep 1
               ifconfig veth${index} down
               sleep 1
               ifconfig veth${index} up
               sleep 1
               pppd file /etc/ppp/options.prfile${index}
          fi
     done
}

function pear_ten_minutes_check()
{
     echo $FUNCNAME
     /root/pear/tools/safe_check.sh

     # multidial_progress=`ps -aux | grep parted.sh | grep multidial | grep -v color`
     # if [[ -z ${multidial_progress} ]]; then
     #      restart_ppp 
     # fi 
}

sleep 600
while true :
do
     pear_ten_minutes_check
     sleep 600
done

