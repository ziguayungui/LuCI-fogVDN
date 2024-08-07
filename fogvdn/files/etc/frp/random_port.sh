#!/bin/bash

[ -e /etc/frp/.port_randomized ] && exit

PORT=$((RANDOM % 5000 + 35000))
sed -i "s/16000/$PORT/g" /etc/frp/frpc.toml
touch /etc/frp/.port_randomized
