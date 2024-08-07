#!/bin/bash

node_info_file="/etc/pear/pear_monitor/node_info.json"
pear_user_info_file="/etc/pear/pear_monitor/pear_user_info.json"

if [ -f "${pear_user_info_file}.bak" ]; then
    echo "pear_user_info.json.bak exists, exiting..."
    exit 0
fi

if [ ! -f "${node_info_file}" ] && [ -r "${pear_user_info_file}" ]; then
    biz_id=$(jq -r '.i' "${pear_user_info_file}")
    jq -n --arg biz_id "$biz_id" '{"biz_id":$biz_id}' > "${node_info_file}"
    mv ${pear_user_info_file} ${pear_user_info_file}.bak
    echo "node_info.json created"
elif [ -f "${node_info_file}" ]; then
    echo "${node_info_file} exists, exiting..."
else
    echo "${pear_user_info_file} does not exist or has no read permission"
fi

exit 0
