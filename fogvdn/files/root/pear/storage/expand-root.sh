#!/bin/sh

# expand-root.sh
# Make root partition as large as possible
#
# Options:
#   -y        Assume "yes" as answer to all prompts and run non-interactively
#
# Remarks:
#
# This tool consumes all available spaces if an Ext4 or XFS filesystem mounted
# on / (root) locates on last partition on the disk.
#
# This tools will automatically install programs used by this tool on Debian-
# based distros.
#
# Calls `resize2fs` on Ext4 **device**, `xfs_growfs -d` on XFS **mountpoint**.

set -e

export LC_ALL=C

SKIP_CONFIRM=0
ROOT_EXT4=0
ROOT_XFS=0

UID=$(id -ru)
if [ "$UID" -ne 0 ]
then
    echo The operation must be done by root. >&2
    exit 127
fi

COLOR=0

if TPUT=$(command -v tput)
then
    COLOR=$("$TPUT" colors 2>/dev/null || true)
fi

if [ "$COLOR" -eq 8 ] 2>/dev/null
then
    PROMPT_RED='\033[31m'
    PROMPT_GREEN='\033[1m\033[32m'
    PROMPT_NORM='\033[0m'
fi
if [ "$COLOR" -ge 16 ] 2>/dev/null
then
    PROMPT_RED='\033[91m'
    PROMPT_GREEN='\033[1m\033[32m'
    PROMPT_NORM='\033[0m'
fi

print_err()
{
    echo "${PROMPT_RED}E:${PROMPT_NORM}" $@ >&2
}

die()
{
    print_err $@
    exit 1
}

pkg_inst()
{
    apt install --quiet --assume-yes --no-install-recommends -o Dpkg::Progress=0 -o Dpkg::Progress-Fancy=0 $@
}

while getopts y OPT_NAME 2>/dev/null
do
     case "$OPT_NAME" in
        y)  SKIP_CONFIRM=1 ;;
        ?)  shift $(($OPTIND - 2))
            die Illegal option ${1}.
            ;;
    esac
done

shift $(($OPTIND - 1))
[ "$#" -gt 0 ] && die Illegal option ${1}.

echo Checking environment ...

if ! FINDMNT=$(command -v findmnt)
then
    print_err Command '`findmnt`' not found. Try installing ...
    pkg_inst util-linux
    FINDMNT=$(command -v findmnt) || die Command '`findmnt`' not found.
fi

# ROOT_DEV    The block device (the partition) mounted on /. E.g. /dev/sda2
# ROOT_SIZE
# ROOT_FS     Filesystem name. Only "ext4" accepted.
# ROOT_MAJMIN Device number in format "major:minor". E.g. 8:2
# ROOT_MIN    Minor device number
# ROOT_PDEV   Parent device path. E.g. /dev/sda

read ROOT_DEV ROOT_SIZE ROOT_FS ROOT_MAJMIN __TRAILING <<EOF
$("$FINDMNT" -efno SOURCE,SIZE,FSTYPE,MAJ:MIN  "/")
EOF

ROOT_MIN=$(echo $ROOT_MAJMIN | cut -d':' -f2)

if [ "$ROOT_FS" = "ext4" ]
then
    ROOT_EXT4=1
fi

if [ "$ROOT_FS" = "xfs" ]
then
    ROOT_XFS=1
fi

[ "$ROOT_EXT4" -eq 1 -o "$ROOT_XFS" -eq 1 ] || die The current root filesystem is not suitable for expanding.

LSBLK=$(command -v lsblk) || die Command '`lsblk`' not found.
ROOT_PDEV=$("$LSBLK" -dno PKNAME "$ROOT_DEV")
[ -n "$ROOT_PDEV" ] || die Could not find particular disk for expanding.

ROOT_PDEV="/dev/$ROOT_PDEV"
PARTX=$(command -v partx) || die Command '`partx`' not found.
FOLLOWING_PARTS=$("$PARTX" -gn "$ROOT_MIN": "$ROOT_PDEV" | wc -l)
[ "$FOLLOWING_PARTS" -eq 1 ] || die The current root filesystem is not located on the last partition of the disk.

PART_SIZE_BYTES=$("$LSBLK" -bdno SIZE "$ROOT_DEV")
BLOCK_SIZE_BYTES=$("$LSBLK" -bdno SIZE "$ROOT_PDEV")
PROPORTION=$(($PART_SIZE_BYTES * 100 / $BLOCK_SIZE_BYTES))
[ "$PROPORTION" -lt 95 ] || die No need to expand root.

if ! FDISK=$(command -v fdisk)
then
    print_err Command '`fdisk`' not found. Try installing ...
    pkg_inst fdisk
    FDISK=$(command -v fdisk) || die Command '`fdisk`' not found.
fi

if [ "$ROOT_EXT4" -eq 1 ]
then
    if ! RESIZE2FS=$(command -v resize2fs)
    then
        print_err Command '`resize2fs`' not found. Try installing ...
        pkg_inst e2fsprogs
        RESIZE2FS=$(command -v resize2fs) || die Command '`resize2fs`' not found.
    fi
fi

if [ "$ROOT_XFS" -eq 1 ]
then
    if ! XFS_GROWFS=$(command -v xfs_growfs)
    then
        print_err Command '`xfs_growfs`' not found. Try installing ...
        pkg_inst xfsprogs
        RESIZE2FS=$(command -v xfs_growfs) || die Command '`xfs_growfs`' not found.
    fi
fi

echo
echo Disk ${PROMPT_GREEN}${ROOT_PDEV}${PROMPT_NORM} Partition ${PROMPT_GREEN}${ROOT_MIN}${PROMPT_NORM}
echo "Size:      " $ROOT_SIZE"iB"
echo "Filesystem:" $ROOT_FS
echo "Mountpoint:" /
echo

if [ "x$SKIP_CONFIRM" != "x1" ]
then
    echo ${PROMPT_RED} '*' DANGEROUS!!! DANGEROUS!!! ${PROMPT_NORM}
    echo ${PROMPT_RED} '*'${PROMPT_NORM} You are altering the partition table on ${PROMPT_GREEN}${ROOT_PDEV}${PROMPT_NORM}
    echo ${PROMPT_RED} '*'${PROMPT_NORM}
    echo ${PROMPT_RED} '*'${PROMPT_NORM} Are you sure to continue?

    printf "Input Y for yes, N for no: "
    read PROMPT_ANSWER
    [ "x$PROMPT_ANSWER" = "xY" -o "x$PROMPT_ANSWER" = "xy" ] || die Aborted.
fi

echo Expanding root partition ...

# "d"elete partition
#  $  partition number
# "n"ew partition
#  $  partition number
# " " default (first available sector)
# " " default (last available sector)
# "w"rite disk

"$FDISK" "$ROOT_PDEV" <<EOF
d
$ROOT_MIN
n
$ROOT_MIN


w
EOF

PAR_CREATED=$("$LSBLK" -dno NAME "$ROOT_DEV" | wc -l)
[ "$PAR_CREATED" -eq 1 ] || die Partition has not been recovered. Further fix may be required.


if [ "$ROOT_EXT4" -eq 1 ]
then
    "$RESIZE2FS" "$ROOT_DEV"
fi

if [ "$ROOT_XFS" -eq 1 ]
then
    "$XFS_GROWFS" -d "/"
fi

read NEWROOT_DEV NEWROOT_SIZE __TRAILING <<EOF
$("$FINDMNT" -efno SOURCE,SIZE  "/")
EOF

echo The new root filesystem on ${NEWROOT_DEV} now has ${NEWROOT_SIZE}iB.
echo Done.
