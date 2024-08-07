#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <name> <port>"
    exit 1
fi

conf_file="/etc/frp/frpc.toml"
flag_file="/etc/frp/.pear_frpc_flag"

if [ -f "${flag_file}" ]; then
    echo "frpc flag file exists"
    exit 1
fi

if [ -n "$(command -v frpc)" ]; then
    frpc_version="$(frpc --version 2>/dev/null)"
else
    frpc_version="$(/usr/sbin/frpc --version 2>/dev/null)"
    if [ -z "${frpc_version}" ]; then
        frpc_version="$(/usr/local/sbin/frpc --version 2>/dev/null)"
    fi
fi

higher_version="$(echo -e "0.52.0\n${frpc_version}" | awk -F. '{printf("%03d%03d%03d\n", $1, $2, $3)}' | sort | awk '{ v = sprintf("%d.%d.%d", int(substr($0, 1, 3)), int(substr($0, 4, 3)), int(substr($0, 7, 3))); print v}' | tail -n 1)"
if [ "${frpc_version}1" != "${higher_version}1" ]; then
    echo "frpc version is lower than 0.52.0"
    exit 1
fi

if [ ! -d "/etc/frp" ]; then
    mkdir -p -m 0755 /etc/frp
fi

old_conf_md5="$(md5sum ${conf_file} | awk '{print $1}')"

cat <<EOF >${conf_file}
serverAddr = "f.webrtc.win"
serverPort = 7000
auth.method = "token"
auth.token = "jdog"
loginFailExit = false

[[proxies]]
name = "${1}"
type = "tcp"
localIp = "127.0.0.1"
localPort = 22
remotePort = ${2}
EOF

new_conf_md5="$(md5sum ${conf_file} | awk '{print $1}')"

if [ -n "$(command -v systemctl)" ]; then
    systemctl enable frpc.service
fi

if [ "${old_conf_md5}1" != "${new_conf_md5}1" ]; then
    if [ -n "$(command -v systemctl)" ]; then
        systemctl restart frpc.service
    else 
        /etc/init.d/frpc.sh restart
    fi
fi

exit 0
