#!/bin/bash
function ff (){
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    ntpdate cn.pool.ntp.org
    hwclock --systohc
}

ff 