#!/bin/bash

# mv /root/pear /root/pear_old
if [ -f /root/pear/var/init ]; then 
    echo "was replaced."
    exit 0;
fi

chmod -R 755 /root/pear
# cp /root/pear_old/pear_remount.sh /root/pear/storage/pear_mount_on_reboot.sh

OS=`grep "^ID=" /etc/os-release | cut -d '=' -f 2- | sed 's|"||g'`


mkdir -p /root/pear/var
mkdir -p /root/pear/log

function set_centos(){
    
    # done
    yum install -y jq
    yum install -y ntpdate 
    cp /root/pear/network/centos/ifup-local.sh /etc/NetworkManager/dispatcher.d/
}


function set_ubuntu(){

    apt install -y jq
    apt install -y ntpdate

    cp /root/pear/network/ubuntu/50-ifup-hooks.sh /etc/networkd-dispatcher/routable.d/

}

function set_openwrt(){
    opkg install jq
    opkg install ntpdate
}

# 打入定时任务
if [ -z "$(cat /etc/crontabs/root | grep pear_cron.sh | grep -v '#')" ]; then 
    echo "* * * * * root /root/pear/cron/pear_cron.sh -1m" >> /etc/crontabs/root
    echo "*/5 * * * * root /root/pear/cron/pear_cron.sh -5m" >> /etc/crontabs/root
    echo "*/30 * * * * root /root/pear/cron/pear_cron.sh -30m" >> /etc/crontabs/root
    echo "15 4 * * * root /root/pear/cron/pear_cron.sh -1d" >> /etc/crontabs/root
fi

/etc/init.d/cron reload

# cp /root/pear/init/pear_init /etc/init.d/pear_init

if [ "${OS}" = "centos" ]; then
    set_centos
elif [ "${OS}" = "ubuntu" ]; then   
    set_ubuntu
fi

rm -rf /root/new
touch /root/pear/var/init
