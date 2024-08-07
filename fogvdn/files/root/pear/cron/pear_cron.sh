#!/bin/bash

# 当前脚本用于cron_tab

# 一分钟定时
function pear_on_minute(){
    local SCRIPT_PATH="/root/pear/cron/1m/*.sh"
    local RECORD_LOG="/root/pear/log/pear_cron_one_minute.log"

    echo `date "+%Y-%m-%d %H:%M:%S"`" 1分钟定时脚本 启动" >> $RECORD_LOG
    for f in $SCRIPT_PATH; do 
        [ -x "$f" ] && [ ! -d "$f" ] && "$f" >> $RECORD_LOG &
    done
    echo `date "+%Y-%m-%d %H:%M:%S"`" 1分钟定时脚本 完成" >> $RECORD_LOG
}

# 5分钟定时
function pear_on_five_minutes(){

    local SCRIPT_PATH="/root/pear/cron/5m/*.sh"
    local RECORD_LOG="/root/pear/log/pear_cron_five_minutes.log"

    echo `date "+%Y-%m-%d %H:%M:%S"`" 5分钟定时脚本 启动" >> $RECORD_LOG
    for f in $SCRIPT_PATH; do 
        [ -x "$f" ] && [ ! -d "$f" ] && "$f" &
    done
    echo `date "+%Y-%m-%d %H:%M:%S"`" 5分钟定时脚本 完成" >> $RECORD_LOG

}
# 30分钟定时
function pear_on_thiry_minutes(){

    local SCRIPT_PATH="/root/pear/cron/30m/*.sh"
    local RECORD_LOG="/root/pear/log/pear_cron_thirty_minutes.log"

    echo `date "+%Y-%m-%d %H:%M:%S"`" 30分钟定时脚本 启动" >> $RECORD_LOG
    for f in $SCRIPT_PATH; do 
        [ -x "$f" ] && [ ! -d "$f" ] && "$f" >> $RECORD_LOG &
    done
    echo `date "+%Y-%m-%d %H:%M:%S"`" 30分钟定时脚本 完成" >> $RECORD_LOG
}

# 天定时
function pear_on_day(){

    local SCRIPT_PATH="/root/pear/cron/1d/*.sh"
    local RECORD_LOG="/root/pear/log/pear_cron_one_day.log"

    echo `date "+%Y-%m-%d %H:%M:%S"`" 1天定时脚本 启动" >> $RECORD_LOG
    for f in $SCRIPT_PATH; do 
        [ -x "$f" ] && [ ! -d "$f" ] && "$f" >> $RECORD_LOG &
    done
    echo `date "+%Y-%m-%d %H:%M:%S"`" 1天定时脚本 完成" >> $RECORD_LOG
}



function usage (){
    echo -e "Usage:"
    echo -e ' -1m \t exec one minute script'
    echo -e ' -5m \t exec five minutes script'
    echo -e ' -30m \t exec thirty minutes script'
    echo -e ' -1d \t exec one day script'
    echo ""
}

interval=$1

case $interval in 
    -1m)
        pear_on_minute
        exit 0;
    ;;
    -5m)
        pear_on_five_minutes
        exit 0;
    ;;
    -30m)
        pear_on_thiry_minutes
        exit 0;
    ;;
    -1d)
        pear_on_day
        exit 0;
    ;;
esac

usage
