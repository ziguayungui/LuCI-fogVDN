#/bin/bash

# set -x

if [ -z "${1}" ] || [ ! -d "${1}" ]; then
    echo "Usage: $0 <install_dir> [download|install]"
    echo "Please specify a mounted directory to store configuration files"
    exit 1
elif [ -n "${2}" ]; then
    if [ "${2}" != "download" ] && [ "${2}" != "install" ]; then
        echo "Usage: $0 <install_dir> [download|install]"
        echo "${2}: invalid option"
        exit 1
    else
        action="${2}"
    fi
fi

install_dir="${1}"
post_cmd=""
architecture=""

check_architecture() {
    local uname_m="$(uname -m)"
    if [ "${uname_m}" = "aarch64" ]; then
        architecture="ARM64"
    elif [ "${uname_m}" = "x86_64" ]; then
        architecture="X64"
    else
        echo "Unsupported architecture: ${uname_m}"
        exit 1
    fi
}

if [ ! -d "${install_dir}" ] || [ -z "$(df "${install_dir}" 2>/dev/null | awk 'NR==2')" ]; then
    echo "${install_dir} is not exist or not mounted"
    exit 1
fi

download() {
    check_architecture
    local update_file_url="https://update.webrtc.win/fogvdn_PEAR_${architecture}_LINUX.json"
    local update_info="$(curl -s "${update_file_url}" | base64 -d)"
    local download_url="$(echo "${update_info}" | jq -r '.fogvdn_url')"
    local download_md5="$(echo "${update_info}" | jq -r '.fogvdn_md5')"
    post_cmd="$(echo "${update_info}" | jq -r '.post_cmd')"

    if [ -z "${download_url}" ] || [ -z "${download_md5}" ]; then
        echo "Failed to get download URL or MD5"
        exit 1
    fi

    local download_file="$(basename "${download_url}")"
    curl -s -o "/tmp/${download_file}" "${download_url}"
    if [ $? -ne 0 ]; then
        echo "Failed to download ${download_file}"
        exit 1
    fi

    if [ "$(md5sum "/tmp/${download_file}" | awk '{print $1}')" != "${download_md5}" ]; then
        echo "MD5 mismatch"
        exit 1
    fi

    mkdir -p "${install_dir}"
    tar -xf "/tmp/${download_file}" -C "${install_dir}"
    if [ $? -ne 0 ]; then
        echo "Failed to extract ${download_file}"
        exit 1
    fi
    rm -f "/tmp/${download_file}"
}

install() {
    # cp -r -f -a "${install_dir}/usr" /

    bin_num="$(ls ${install_dir}/usr/sbin | wc -l)"
    for i in "$(seq 1 ${bin_num})"; do
        bin_file="$(ls ${install_dir}/usr/sbin | awk "NR==${i}")"
        if [ ! -L "/usr/sbin/${bin_file}" ] || [ "$(realpath /usr/sbin/${bin_file})" != "${install_dir}/usr/sbin/${bin_file}" ]; then
            rm -rf "/usr/sbin/${bin_file}"
            ln -sf "${install_dir}/usr/sbin/${bin_file}" "/usr/sbin/${bin_file}"
        fi
    done

    if [ ! -L "/etc/pear" ] || [ "$(realpath /etc/pear)" != "${install_dir}/etc/pear" ]; then
        rm -rf /etc/pear
        ln -sf "${install_dir}/etc/pear" /etc/pear
    fi
    mkdir -p "${install_dir}/opt/pear"
    if [ ! -L "/opt/pear" ] || [ "$(realpath /opt/pear)" != "${install_dir}/opt/pear" ]; then
        rm -rf /opt/pear
        ln -sf "${install_dir}/opt/pear" /opt/pear
    fi
    if [ ! -L "/root/pear" ] || [ "$(realpath /root/pear)" != "${install_dir}/root/pear" ]; then
        rm -rf /root/pear
        ln -sf "${install_dir}/root/pear" /root/pear
    fi
    if [ -n "${post_cmd}" ]; then
        chmod +x "${post_cmd}"
        ${post_cmd}
    fi
}

deploy() {
    download
    install
}

if [ -n "${action}" ]; then
    ${action}
    echo "${action} done"
else
    deploy
    echo "deploy done"
fi

exit 0
