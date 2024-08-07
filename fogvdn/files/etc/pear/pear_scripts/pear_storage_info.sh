#!/bin/bash
# set -x
info_file="/etc/pear/pear_monitor/storage_info.json"
conf_file="/etc/pear/pear_monitor/config.json"

formatted_info="["

# Get the storage information from the config file
storages=($(jq -rM .storage[] "$conf_file"))

# Get the disk information from the system
for storage in "${storages[@]}"; do
    if [ "$(df "$storage" 2>/dev/null | awk 'NR==2' | wc -l)1" = "11" ]; then
        part_name=$(findmnt -n -o SOURCE --target "$storage")
        disk_name=$(lsblk --paths --noheadings --output PKNAME "$part_name" | head -n 1)
        storage_info_pairs=$(lsblk --bytes --pair --paths -o NAME,VENDOR,MODEL,SERIAL,SIZE,ROTA,TYPE "$disk_name" | grep disk)
        storage_info="$(
            echo "$storage_info_pairs" |
                sed -e 's/\(NAME\|VENDOR\|MODEL\|SERIAL\|SIZE\|ROTA\|TYPE\)/"\1"/g' \
                    -e 's/.*/{&},/' -e '$s/,$//' \
                    -e 's/\" "/", "/g' -e 's/":"/": "/g' \
                    -e 's/}"/}"/g' \
                    -e 's/"="/":"/g' #-e '1s/^/[/' -e '$s/$/]/' \
        )"
        storage_info="$(echo ${storage_info} | jq '. += {"PATH":"'"${storage}"'"}')"

        if [ "${formatted_info}1" != "[1" ]; then
            formatted_info="${formatted_info},"
        fi
        formatted_info="${formatted_info}${storage_info}"
    fi
done
formatted_info="${formatted_info}]"
formatted_info=$(echo "$formatted_info" | jq '{storage_info:.}')

os_drive_part=$(findmnt -n -o SOURCE --target /)
os_drive_name=$(lsblk --paths --noheadings --output PKNAME "$os_drive_part" | head -n 1)
os_drive_serial=$(lsblk --noheadings --output SERIAL "${os_drive_name}" | head -n 1)

formatted_info=$(echo ${formatted_info} | jq '. += {"os_drive_serial":"'"${os_drive_serial}"'"}')

echo "$formatted_info"
echo "$formatted_info" >"$info_file"

# # Get disk information
# disk_info=$(lsblk --pair --paths -o NAME,VENDOR,MODEL,SERIAL,SIZE,ROTA,TYPE | grep disk)
# disk_count=$(lsblk --pair --paths -o NAME,VENDOR,MODEL,SERIAL,SIZE,ROTA,TYPE | grep disk | wc -l)

# # Format the disk information
# formatted_info=$(echo "$disk_info" | sed -e 's/\(NAME\|VENDOR\|MODEL\|SERIAL\|SIZE\|ROTA\|TYPE\)/"\1"/g' \
#                                          -e 's/.*/{&},/' -e '$s/,$//' \
#                                          -e 's/\" "/", "/g' -e 's/":"/": "/g' \
#                                          -e 's/}"/}"/g' -e '1s/^/[/' -e '$s/$/]/' \
#                                          -e 's/"="/":"/g')

# # Output the formatted disk information
# echo "$formatted_info" | jq '{disk_info:.}' > "$info_file"

exit 0
