#!/bin/bash

PLATFORM=PEAR_2608_X64_LINUX
LOG_PATH=/tmp/scripts.log
INSTALL_PATH="$1"
SCRIPT_PATH=${INSTALL_PATH}/etc/pear/pear_scripts/tencent_sl

SCRIPT_NAMES=(
  tencent_sl_alive.sh
  check_config.sh
  watchdog.sh
  dispatch.sh
  check.sh
)

SCRIPT_TOGGLES=(
  1           # tencent_sl_status.sh
  0           # check_config.sh
  0           # watchdog.sh
  1           # dispatch.sh
  1           # check.sh
)

SCRIPT_BACKGROUND=(
  1           # tencent_sl_alive.sh
  0           # check_config.sh
  1           # watchdog.sh
  1           # dispatch.sh
  1           # check.sh
)

# check files and toggles
if [[ ${#SCRIPT_NAMES[@]} -ne ${#SCRIPT_TOGGLES[@]} ]]; then
  datetime=`date "+%Y-%m-%d %H:%M:%S"`
  echo "${datetime} [FATAL] incorrect params"
  exit 1
fi

# do
for i in $(seq 0 ${#SCRIPT_NAMES})
do
  # skip the last
  if [[ -z ${SCRIPT_NAMES[$i]} ]]; then
    continue
  fi

  # kill if running
  ps_result=`ps -ef | grep ${SCRIPT_NAMES[$i]} | grep -v grep`
  if [[ -n ${ps_result} ]]; then
    killall ${SCRIPT_NAMES[$i]}
  fi

  # check if close by toggles
  if [[ ${SCRIPT_TOGGLES[$i]} -ne 1 ]]; then
    continue
  fi

  # check if exist
  script_path=${SCRIPT_PATH}/${SCRIPT_NAMES[$i]}
  if [[ ! -f ${script_path} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] expected to run ${script_path}, but not exist"
    continue
  fi

  # run 
  chmod +x ${script_path}
  datetime=`date "+%Y-%m-%d %H:%M:%S"`
  echo "${datetime} [INFO ] running script: ${script_path}"
  if [[ ${SCRIPT_BACKGROUND[$i]} -eq 0 ]]; then
    ${script_path} ${PLATFORM}
  else
    ${script_path} ${PLATFORM} &
  fi
done

echo "scripts done"
