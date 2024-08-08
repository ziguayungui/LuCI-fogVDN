#!/bin/sh /etc/rc.common
### BEGIN INIT INFO
# Provides:          xc_cdn
# Required-Start:    $network $local_fs pear_init
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: PearCDN Service
# Description:       Manages the PearCDN service with start, stop, and restart commands.
### END INIT INFO

START=99
USE_PROCD=1

check_local_timezone() {
  dt=$(date "+%H:%M" | grep "00:00")
  if [[ -n ${dt} ]]; then
    # do sync time
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    ntpdate cn.pool.ntp.org
    hwclock -u --systz
  fi
}

# new_conf_gen() {
#   script_file="/etc/pear/pear_scripts/new-conf-gen.sh"
#   if [ ! -f /etc/pear/pear_monitor/config.json ]; then
#     chmod +x ${script_file} && ${script_file}
#   fi
# }

check_tools_status() {
  # check ntpdate
  exist=$(which ntpdate | awk '{print $2}')
  system=$(cat /etc/issue | grep Ubuntu | wc -l)

  if [[ -z ${exist} ]]; then
    if [[ -z ${system} ]]; then
      yum install ntpdate -y
    else
      apt-get install ntpdate -y
    fi
  fi

  # check smartctl
  exist2=$(which smartctl | awk '{print $2}')

  if [[ -z ${exist2} ]]; then
    if [[ -z ${system} ]]; then
      yum install smartmontools -y
    else
      apt-get install smartmontools -y
    fi
  fi

  # # check net-tools
  # exist3=$(whereis ifconfig | awk '{print $2}')

  # if [[ -z ${exist3} ]]; then
  #   if [[ -z ${system} ]]; then
  #     yum install net-tools -y
  #   else
  #     apt-get install net-tools -y
  #   fi
  # fi
}

start_frp() {
#   /etc/init.d/frpc.sh alive
#   if [ $? -ne 0 ]; then
    /etc/init.d/frpc.sh restart
#   fi
}

# enable_service() {
#   if [ -n "$(command -v systemctl)" ]; then
#     xc_cdn_is_enable=$(systemctl is-enabled xc_cdn.service | grep "enabled" | wc -l)
#     pear_init_is_enable=$(systemctl is-enabled pear_init.service | grep "enabled" | wc -l)

#     if [ ${pear_init_is_enable} -eq 0 ]; then
#       systemctl enable pear_init.service
#     fi
#     if [ ${xc_cdn_is_enable} -eq 0 ]; then
#       systemctl enable xc_cdn.service
#     fi
#   fi
# }

stop_plugin() {
  if [ -f "/etc/pear/pear_plugin/docker_cp_name.conf" ]; then
    plugin_stop_file="$(cat /etc/pear/pear_plugin/docker_cp_name.conf).sh"
  else
    plugin_stop_file=".sh"
  fi
  if [ "0${plugin_stop_file}" = "0.sh" ]; then
    plugin_stop_files=$(ls /etc/pear/pear_plugin/plugin_stop/)
    echo "${plugin_stop_files}" | while read plugin_stop_file; do
      /etc/pear/pear_plugin/plugin_stop/${plugin_stop_file}
    done
  elif [ -f /etc/pear/pear_plugin/plugin_stop/${plugin_stop_file} ]; then
    /etc/pear/pear_plugin/plugin_stop/${plugin_stop_file}
  fi
}

stop_all_groum_Guarded_by_pear_restart() {
  conf_file="/etc/pear/pear_restart/pids.conf"
  if [ -f ${conf_file} ]; then
    cat ${conf_file} | while read line; do
      if [ -n "${line}" ]; then
        pid=$(echo ${line} | awk '{print $2}')
        if [ -n "${pid}" ]; then
          kill -SIGTERM ${pid}
        fi
      fi
    done
  fi
  echo '' >${conf_file}
}

start_app() {
#   enable_service
  # new_conf_gen
#   /etc/pear/pear_update/post_command.sh
#   /etc/pear/pear_scripts/replace.sh
  /etc/pear/pear_scripts/pear_storage_info.sh
  check_local_timezone
#   check_tools_status
  start_frp

  # /usr/sbin/pear_restart --install_path=/ &
  procd_open_instance
  procd_set_param command /usr/sbin/pear_restart --install_path=/
  procd_close_instance

  # nohup /root/pear/tools/post.sh >/dev/null 2>&1 &
  # nohup /root/pear/tools/pear_one_minute_check.sh >/dev/null 2>&1 &
  procd_open_instance
  procd_set_param command /root/pear/tools/pear_one_minute_check.sh
  procd_close_instance

  # nohup /root/pear/tools/pear_ten_minutes_check.sh >/dev/null 2>&1 &
  procd_open_instance
  procd_set_param command /root/pear/tools/pear_ten_minutes_check.sh
  procd_close_instance

  # nohup /root/pear/tools/pear_debug.sh >/dev/null 2>&1 &
  procd_open_instance
  procd_set_param command /root/pear/tools/pear_debug.sh
  procd_close_instance
#   nohup /root/pear/tools/install.sh >/dev/null 2>&1 &
  # sed -i 's/sleep 5/sleep 20/g' /etc/rc.local
  ulimit -HSn 131072
  ulimit -c unlimited
}

stop_app() {
  killall -9 pear_restart
  sleep 2
  killall -9 pear_update
  killall -9 pear_monitor
  killall -9 pear_httpd
  killall -9 pear_s
  killall -9 socks_server
  killall -9 scan.sh
#   killall -9 install.sh
  killall -9 pear_one_minute_check.sh
  killall -9 pear_ten_minutes_check.sh
  killall -9 pear_debug.sh
  killall -9 ptty
  stop_plugin
  stop_all_groum_Guarded_by_pear_restart
}

stop_some_app() {
  killall -9 pear_restart
  sleep 2
  killall -9 pear_update
  killall -9 pear_monitor
  killall -9 pear_httpd
  killall -9 pear_s
  killall -9 socks_server
  killall -9 scan.sh
  killall -9 pear_findppp
#   killall -9 install.sh
  killall -9 pear_one_minute_check.sh
  killall -9 pear_ten_minutes_check.sh
  killall -9 pear_debug.sh
  stop_all_groum_Guarded_by_pear_restart
}

start_service() {
  stop_app
  start_app
}

stop_service() {
  stop_app
}

restart() {
  stop_app
  start_app
}

reload_service() {
  stop_some_app
  start_app
}
