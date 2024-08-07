#!/bin/bash
# set -x
sleep 30
echo "begin debug"

user_id=""
user_info_file=""
pear_monitor_version="$(pear_monitor -v | awk '{print $3}')"

PTTY_PORT=${PTTY_PORT:=4981}

EVERY_SLEEP=300

get_user_id() {
        if [ -n "${user_id}" ]; then
                echo $user_id
                exit 0
        fi

        if [ "${pear_monitor_version}" -lt "613" ]; then
                user_info_file="/etc/pear/pear_monitor/pear_user_info.json"
                while [ ! -r "${user_info_file}" ]; do
                        sleep ${EVERY_SLEEP}
                done
                echo $(sed -n 's/.*\"i\":\"\([0-9a-z\-]\+\).*/\1/p' "${user_info_file}")
        else
                user_info_file="/etc/pear/pear_monitor/node_info.json"
                while [ ! -r "${user_info_file}" ]; do
                        sleep ${EVERY_SLEEP}
                done
                echo $(jq -r '.biz_id' "${user_info_file}")
        fi
}

open_debug() {
        ptty_exist=$(pgrep ptty)
        [ -n "${ptty_exist}" ] && echo ptty pid="${ptty_exist}" || echo ptty not running
        if [ -z "${ptty_exist}" ]; then

                user_id=$(get_user_id)

                echo $user_id
                nohup env TERM=xterm-256color /usr/sbin/ptty -I "${user_id}" -h console.webrtc.win -p "${PTTY_PORT}" -a -d TEST_NODE >/dev/null 2>&1 &
        fi
}

while true; do
        open_debug
        sleep ${EVERY_SLEEP}
done
