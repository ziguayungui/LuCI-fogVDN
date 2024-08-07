#!/bin/bash

# 备份目录
backup_dir=/root/pear/rc.backup

# 函数：修复/etc下的rc相关符号链接
# 该函数检查并修复/etc目录下指定的目录或符号链接
# 参数1: 目标目录的路径
# 参数2: 需要修复的目录或链接名
repair_rc_link()
{
    cd /etc
    current_dir=$(pwd)
    if [ "1${current_dir}" != "1/etc" ]; then
        echo "**repair_rc_link: pwd is not /etc, but ${current_dir}"
        exit 1
    fi
    if [ -d "$1" ]; then
        # echo "-repair_rc_link: $1 is exists and it's a directory"
        [ ! -L "$2" ] && cp -r -v -f -a "$2" "${backup_dir}/"
        rm -rf "$2"    
        ln -sf "$1" "$2"
        echo "--repair_rc_link: /etc/$2 repaired"
    else
        echo "-repair_rc_link: /etc/$1 is not exists or not a directory"
    fi
}

# 函数：添加服务
# 在特定rcN.d目录下添加服务的符号链接
# 参数1: rc.d目录名（如rc3.d）
# 参数2: 服务链接前缀（如S16）
# 参数3: 服务脚本名称（如xc_cdn.sh）
add_service()
{
    cd "/etc/$1"
    current_dir=$(pwd)
    if [ "1${current_dir}" != "1/etc/$1" ]; then
        echo "**add_service: pwd is not /etc/$1, but ${current_dir}"
        exit 1
    fi
    if [ ! -L "$2$3" ]; then
        # echo "-add_service: /etc/$1/$2$3 is not a link"
        if [ -e "$2$3" ]; then
            mkdir -p "${backup_dir}/$1"
            cp -v -f -a "$2$3" "${backup_dir}/$1/$2$3"
        fi    
        rm -rf "$2$3"
        ln -sf "../init.d/$3" "$2$3"
        echo "--add_service: /etc/$1/$2$3 added"
    else
        echo "-add_service: /etc/$1/$2$3 is a link"
    fi
}

# 确保备份目录存在
mkdir -p ${backup_dir}

# 修复init.d目录
cd /etc
current_dir=$(pwd)
if [ "1${current_dir}" = "1/etc" ]; then
    if [ -d rc.d/init.d ]; then
        if [ ! -L init.d ]; then
            files=$(ls init.d)
            for file in $files; do
                if [ -e init.d/$file ]; then
                    cp -v -f -a init.d/$file rc.d/init.d/
                fi
            done
            cp -r -v -f -a init.d ${backup_dir}/init.d
        fi   
        rm -rf init.d
        ln -sf rc.d/init.d init.d
        echo "--/etc/init.d repaired"
    else
        echo "-/etc/rc.d/init.d is not exists or not a directory"
    fi
else
    echo "**repair_init.d: pwd is not /etc, but ${current_dir}"
fi

# 检查并修复所有rc.d目录
rc_dirs=(rc0.d rc1.d rc2.d rc3.d rc4.d rc5.d rc6.d rcS.d)
for rc_dir in ${rc_dirs[@]}; do
    repair_rc_link rc.d/${rc_dir} ${rc_dir}
done

# 修复rc.local
cd /etc
current_dir=$(pwd)
if [ "1${current_dir}" = "1/etc" ]; then
    if [ -e rc.d/rc.local ]; then
        [ ! -L rc.local ] && cp -v -f -a rc.local ${backup_dir}/rc.local
        rm -rf rc.local
        ln -sf rc.d/rc.local rc.local
        echo "--/etc/rc.local repaired"
    else
        echo "-/etc/rc.d/rc.local is not exists"
    fi
else
    echo "**repair_rc.local: pwd is not /etc, but ${current_dir}"
fi

# 为runlevel3/5/S添加xc_cdn.sh服务
add_service rc3.d S16 xc_cdn.sh
add_service rc5.d S16 xc_cdn.sh
add_service rcS.d S16 xc_cdn.sh

# 为runlevel3/5/S添加pear_init.sh服务
add_service rc3.d S14 pear_init.sh
add_service rc5.d S14 pear_init.sh
add_service rcS.d S14 pear_init.sh

echo "rc_repair: done"
exit 0

# if [ -d rc.d/rc3.d ] && [ ! -L rc3.d ]; then
#     cp -r -v -f -a rc3.d ${backup_dir}/rc3.d
#     rm -rf rc3.d
#     ln -sf rc.d/rc3.d rc3.d
# fi
# if [ -d rc.d/rc5.d ] && [ ! -L rc5.d ]; then
#     cp -r -v -f -a rc5.d ${backup_dir}/rc5.d
#     rm -rf rc5.d
#     ln -sf rc.d/rc5.d rc5.d
# fi
# if [ -d rc.d/rcS.d ] && [ ! -L rcS.d ]; then
#     cp -r -v -f -a rcS.d ${backup_dir}/rcS.d
#     rm -rf rcS.d
#     ln -sf rc.d/rcS.d rcS.d
# fi
# if [ -f rc.d/rc.local ] && [ ! -L rc.local ]; then
#     cp -v -f -a rc.local ${backup_dir}/rc.local
#     rm -rf rc.local
#     ln -sf rc.d/rc.local rc.local
# fi

# cd /etc/rc3.d
# if [ ! -L S16xc_cdn.sh ]; then
#     if [ -e S16xc_cdn.sh ]; then
#         mkdir -p ${backup_dir}/rc3.d
#         cp -v -f -a S16xc_cdn.sh ${backup_dir}/rc3.d/S16xc_cdn.sh
#         rm -rf S16xc_cdn.sh
#     fi
#     ln -sf ../init.d/xc_cdn.sh S16xc_cdn.sh
# fi
# cd /etc/rc5.d
# if [ ! -L S16xc_cdn.sh ]; then
#     if [ -e S16xc_cdn.sh ]; then
#         mkdir -p ${backup_dir}/rc5.d
#         cp -v -f -a S16xc_cdn.sh ${backup_dir}/rc5.d/S16xc_cdn.sh
#         rm -rf S16xc_cdn.sh
#     fi
#     ln -sf ../init.d/xc_cdn.sh S16xc_cdn.sh
# fi
# cd /etc/rcS.d
# if [ ! -L S16xc_cdn.sh ]; then
#     if [ -e S16xc_cdn.sh ]; then
#         mkdir -p ${backup_dir}/rcS.d
#         cp -v -f -a S16xc_cdn.sh ${backup_dir}/rcS.d/S16xc_cdn.sh
#         rm -rf S16xc_cdn.sh
#     fi
#     ln -sf ../init.d/xc_cdn.sh S16xc_cdn.sh
# fi
