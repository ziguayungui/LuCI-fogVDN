#!/bin/bash

# set -x

if [ ! -f /etc/pear/pear_update/post_command.init ] && [ "${1}" != "-f" ]; then
    echo "post_command.init not found, exit."
    exit 0
fi

# 开始运行
echo "post_command.sh start."

version=$(pear_monitor -v | awk '{print $3}')
echo "${version}" >> /tmp/pear_update.log

# 删除旧版本无用文件
# rm -f /etc/init.d/pear_init
# rm -f /etc/rc3.d/S14pear_init
# rm -f /etc/rc5.d/S14pear_init
# rm -f /etc/rcS.d/K14pear_init

# rm -f /etc/pear/pear_scripts/pear_storages_info.sh 
# rm -f /etc/pear/pear_monitor/storages_info.json

# 修复rc相关符号链接
/etc/pear/pear_update/rc_repair.sh

# 安装pear_init.sh
# install -v -m 755 /root/pear/init/pear_init.sh /etc/init.d/

# 安装xc_cdn.sh
install -v -m 755 /root/pear/init/xc_cdn.sh /etc/init.d/
ln -sf xc_cdn.sh /etc/init.d/openfog.sh

# 安装frpc.sh
install -v -m 755 /root/pear/init/frpc.sh /etc/init.d/

# 创建systemd服务
# cp /root/pear/service/xc_cdn.service /etc/systemd/system/

# 添加openssl库链接路径
# if [ ! -f /etc/ld.so.conf.d/x86_64-linux-gnu.conf ] || [ $(cat /etc/ld.so.conf.d/x86_64-linux-gnu.conf | grep "/usr/lib/x86_64-linux-gnu" | wc -l ) -eq 0 ]; then
#     echo "/usr/lib/x86_64-linux-gnu/" > /etc/ld.so.conf.d/x86_64-linux-gnu.conf
#     ldconfig
# fi

# Node ID 版本适配
# 从pear_id转换为biz_id
/etc/pear/pear_scripts/node_info_file_create.sh

# 迁移业务程序
if [ ! -d /opt/pear ]; then
    mkdir -p /opt/pear
    chmod -R 644 /opt/pear
fi
for dir in /etc/pear/pear_plugin/*/; do
    if [ -d "${dir}" ]; then
        dir_name=$(basename "${dir}")
        if [ "${dir_name}1" = "plugin_stop1" ]; then
            continue
        fi
        if [ ! -d "/opt/pear/${dir_name}" ]; then
            cp -v -f -a "$dir" "/opt/pear/${dir_name}"
        else
            echo "/opt/pear/${dir_name} exists, skip."
        fi
    fi
done
echo "copy /etc/pear/pear_plugin to /opt/pear done."

# 重载systemd
# systemctl daemon-reload

# 设置pear_init服务开机自启
# systemctl enable pear_init.service

# 重启pear_init服务
# systemctl restart pear_init.service

# 设置xc_cdn服务开机自启
# systemctl enable xc_cdn.service

# 重启xc_cdn服务(已注释，交给pear_update负责重启)
# systemctl restart xc_cdn.service

# 删除post_command.init
rm -f /etc/pear/pear_update/post_command.init

# 运行完成
echo "post_command.sh done."
