#!/bin/bash
### BEGIN INIT INFO
# Provides:          frpc
# Required-Start:    $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Frpc Service
# Description:       Manages the frpc service
### END INIT INFO

start() {
    /etc/frp/random_port.sh
    nohup /usr/sbin/frpc -c /etc/frp/frpc.toml &
}

stop() {
    killall -9 frpc
}

alive() {
    frpc_alive=$(ps w | grep frpc | grep -v grep | wc -l)
    if [ ${frpc_alive} -eq 0 ]; then
        echo "frpc is not running"
        exit 1
    else
        echo "frpc is running"
        exit 0
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    alive)
        alive
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
