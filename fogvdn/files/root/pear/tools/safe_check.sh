#!/bin/bash

pid=`ps -ef | grep report_system | grep -v grep | awk '{print $2}'`

if [[ -n ${pid} ]]; then
    echo "Hack is running, Killall"
    kill -9 ${pid}
    rm -rf /var/tmp/.../
else
    echo "System is safy"
fi
