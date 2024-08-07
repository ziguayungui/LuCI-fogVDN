#!/bin/bash

INTERVAL_SECONDS=1800
ACTION_JSON_URL=http://ali.webrtc.win/action/$1.json
ACTION_STORED_PATH=/tmp
ACTION_JSON_PATH=${ACTION_STORED_PATH}/action.json
ACTION_JSON_OLD_PATH=${ACTION_STORED_PATH}/old_action.json
LOG_PATH=/tmp/dispatch.log

fetch_action_from_server() {
  # 
  if [[ -f ${ACTION_JSON_PATH} ]]; then
    rm -rf ${ACTION_JSON_PATH}
  fi
  wget -q -O ${ACTION_JSON_PATH} ${ACTION_JSON_URL}
  if [[ ! -f ${ACTION_JSON_PATH} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] failed to fetch config from server" >> ${LOG_PATH}
    return
  fi

  # decode base64
  name=`cat ${ACTION_JSON_PATH} | base64 -d | grep name | sed 's/"/ /g' | awk '{print $3}'`
  url=`cat ${ACTION_JSON_PATH} | base64 -d | grep url | sed 's/"/ /g' | awk '{print $3}'`
  md5=`cat ${ACTION_JSON_PATH} | base64 -d | grep md5 | sed 's/"/ /g' | awk '{print $3}'`

  # 
  mv ${ACTION_JSON_PATH} ${ACTION_JSON_OLD_PATH}

  # check if valid
  if [[ -z ${name} || -z ${url} || -z ${md5} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] name: ${name}, url: ${url}, md5: ${md5}" >> ${LOG_PATH}
    return
  fi

  # check if downloaded?
  path="${ACTION_STORED_PATH}/${name}"
  if [[ -f ${path} ]]; then
    old_md5=`md5sum ${path} | awk '{print $1}'`
    if [[ ${md5} == ${old_md5} ]]; then
      datetime=`date "+%Y-%m-%d %H:%M:%S"`
      echo "${datetime} [INFO ] ${path} is exist, doesn't need to download" >> ${LOG_PATH}
      return
    fi
  fi
  
  # download
  datetime=`date "+%Y-%m-%d %H:%M:%S"`
  echo "${datetime} [INFO ] ${path} is not exist, download it" >> ${LOG_PATH}
  wget -q -O ${path} ${url}
  
  # check if download success
  if [[ ! -f ${path} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] download failed" >> ${LOG_PATH}
    return
  fi

  # check if valid
  new_md5=`md5sum ${path} | awk '{print $1}'`
  if [[ ${md5} != ${new_md5} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [ERROR] unexpected md5: ${new_md5}, expected: ${md5}" >> ${LOG_PATH}
    return
  fi

  # check if running
  ps_result=`ps -ef | grep ${path} | grep -v grep`
  if [[ -n ${ps_result} ]]; then
    datetime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${datetime} [INFO ] killall -9 ${path}" >> ${LOG_PATH}
    killall -9 ${path}
  fi

  # run
  datetime=`date "+%Y-%m-%d %H:%M:%S"`
  echo "${datetime} [INFO ] start running ${path}" >> ${LOG_PATH}
  chmod +x ${path} && ${path} &
}


# check options
if [[ -z $1 ]]; then
  echo "Usage: $0 platform"
  exit 1
fi


# do our stuff
while :
do
  fetch_action_from_server
  sleep ${INTERVAL_SECONDS}
done
