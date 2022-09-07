#!/bin/bash

# Console colors
_C_DF=$'\033[0m'
_C_RD=$'\033[31m'
_C_OR=$'\033[33m'
_C_GR=$'\033[36m'
_C_BL=$'\033[94m'
_C_DM=$'\033[2m'
_C_MG=$'\033[95m'

_M_SUCCESS="[$_C_GR+$_C_DF]"
_M_WARNING="$_C_OR[$_C_RD!$_C_OR]$_C_DF"
_M_MSG="$_C_DM[~]"
_M_QUESTION="[$_C_MG?$_C_DF]"

function out_blue() {
    echo -e "$_C_BL$1$_C_DF"
}

function warn() {
    echo -e "$_M_WARNING $_C_OR$1$_C_DF"
}

trap ctrl_c INT
function ctrl_c() {
    echo
    warn "Interrupted"
    exit 1
}

### REQUIREMENTS ###

echo -e "\n$_M_MSG Checking requirements...$_C_DF\n"

OS=$(hostnamectl | grep "Operating System" | awk '{ print $3 " " $4 " " $5 }')
OSNAME=`echo $OS | awk '{ print $1 }'`
OSVERSION=`echo $OS | awk '{ print $2 }'`

# Check for the kernel
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    warn "You are running $OSTYPE, but linux required."
    exit 1
fi

echo -ne "$_M_SUCCESS Operating System:\t"
out_blue $OS

# Check for the operating system and version
if [[ $OSNAME -ne "Ubuntu" ]]; then
    warn "You are using $OSNAME, but Ubuntu is recommended."
else
    if [[ ${OSVERSION:0:2} -lt 14 ]]; then
        warn "Version $OSVERSION isn't supported. Minimum required version is 14.04"
        exit 1
    fi
fi

# Check for the architecture
ARCH=$(uname -m)

if [[ $ARCH -ne "x86_64" ]]; then
    warn "Your processor architecture is $ARCH, but 64-bit is required."
    exit 1
fi

# Check for an amount of RAM available for a build
RAM_KB="$(expr $(awk '/MemTotal/{print $2}' /proc/meminfo))"
RAM_GB=$(($RAM_KB / 1024 / 1024))

RAM_GB_exact_full=`awk "BEGIN {print (16287660)/1024/1024}"`
RAM_GB_exact=${RAM_GB_exact_full:0:4}

if [[ $RAM_GB -lt 6 ]]; then
    warn "Your machine has$_C_RD $RAM_GB_exact GB$_C_OR of RAM, but at least $_C_RD 16 GB$_C_OR of available RAM is required."
    exit 1
fi

#RAM_GB=16
echo -ne "$_M_SUCCESS RAM:\t\t"
out_blue "$RAM_GB_exact GB"

if [[ $RAM_GB -lt 16 ]]; then
    warn "Note: at least$_C_RD 16 GB$_C_OR of available RAM is required."
fi

# Check for the disk size
DISK_CAPACITY=$(df -H . | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $2 }' | rev | cut -c 2- | rev)

if [[ $DISK_CAPACITY < 250 ]]; then
    echo
    warn "The directory you specified is on a disk with insufficient disk space for a build. You need at least$_C_RD 250 GB$_C_OR of free disk space to check out the code and an extra$_C_RD 150 GB$_C_OR to build it."
    exit 1
fi

echo -ne "$_M_SUCCESS Disk size:\t\t"
out_blue "$DISK_CAPACITY GB"

### BUILD ENVIRONMENT ###

echo -e "\n$_M_MSG Choosing targets...$_C_DF"

VENDOR_NAMES="ASUS BQ Essential F(x)tec Fairphone Google LeEco Lenovo LG Motorola Nextbit Nokia Nubia NVIDIA OnePlus Razer Samsung SHIFT Sony Walmart Xiaomi ZUK"

i=0
for v in $VENDOR_NAMES; do
    if [[ "$(( $i % 4 ))" -eq 0 ]]; then
        echo
    fi
    printf "    $_C_GR%-4s $_C_BL%-11s$_C_DF" "[$(($i + 1))]" "$v"
    ((i++))
done
echo -e "\n"

read -p "$_M_SUCCESS Select a vendor "$'(\033[36m1-22\033[0m): ' vendor_index
while [[ !("$vendor_index" =~ ^[0-9]+$) || $vendor_index -lt 1 || $vendor_index -gt 22 ]]; do
    echo -en $'\033[1A\033[0K'
    read -p "$_M_SUCCESS Select a vendor "$'(\033[36m1-22\033[0m): ' vendor_index
done

VENDOR_FULL=$(echo $VENDOR_NAMES | cut -d " " -f $vendor_index)
VENDOR=""

if [[ $VENDOR_FULL == "F(x)tec" ]]; then
    VENDOR="f-x-tec"
else
    VENDOR=$(echo "$VENDOR_FULL" | awk '{print tolower($0)}')
fi

echo -ne "$_M_SUCCESS Looking for vendor devices. "

WEBSITE_VENDOR_CODENAMES="https://wiki.lineageos.org/devices/"
GITHUB_CODENAMES_PAGES='https://github.com/orgs/LineageOS/repositories?q=android_device_'"$VENDOR"'_&type=public&language=&sort='

TOTAL_PAGES=$(curl -s $GITHUB_CODENAMES_PAGES | sed -nE '/data-total-pages/p' | sed 's/.*data-total-pages="//g' | sed 's/">1<\/em>.*//g')

if [[ -z $TOTAL_PAGES ]]; then
    TOTAL_PAGES=1
fi

website_vendor_codenames=$(curl -s $WEBSITE_VENDOR_CODENAMES | sed -En "/<div\sclass=\"item \"\sonClick=\"location.href='\/devices\/[a-zA-Z0-9_]/p" | sed "s/.*devices\///g" | sed "s/[\'\"\>]//g")
github_vendor_codenames=""

current_page=1
while [[ $current_page -le $TOTAL_PAGES ]]; do
    link='https://github.com/orgs/LineageOS/repositories?language=&page='"$current_page"'&q=android_device_'"$VENDOR"'_&sort=&type=public'
    github_vendor_codenames+=$(curl -s $link | sed -nE '/^[ \t]*android_device_'"$VENDOR"'_\w/p' | sed 's/^[ \t]*android_device_'"$VENDOR"'_//g')
    github_vendor_codenames+=" "
    ((current_page++))
done

VENDOR_CODENAMES=$( comm -12 <(sed 's/ /\n/g' <<<$website_vendor_codenames | sort) <(sed 's/ /\n/g' <<<$github_vendor_codenames | sort) )

total_codenames=0
for v in $VENDOR_CODENAMES; do
    ((total_codenames++))
done

echo -e "Found $_C_GR$total_codenames$_C_DF device(s):"
i=0
for v in $VENDOR_CODENAMES; do
    if [[ "$(( $i % 4 ))" -eq 0 ]]; then
        echo
    fi
    printf "    $_C_GR%-4s $_C_BL%-11s$_C_DF" "[$(($i + 1))]" "$v"
    ((i++))
done
echo -e "\n"

read -p "$_M_SUCCESS Select a device "$'(\033[36m1-'$total_codenames$'\033[0m): ' device_index
while [[ !("$device_index" =~ ^[0-9]+$) || $device_index -lt 1 || $device_index -gt $total_codenames ]]; do
    echo -en $'\033[1A\033[0K'
    read -p "$_M_SUCCESS Select a device "$'(\033[36m1-'$total_codenames$'\033[0m): ' device_index
done

DEVICE_CODENAME=$(echo $VENDOR_CODENAMES | cut -d " " -f $device_index)

echo -e "$_M_SUCCESS You have chosen $_C_BL$VENDOR_FULL $_C_DF($_C_BL$DEVICE_CODENAME$_C_DF)."

echo -e "\n$_M_MSG Preparing for build(s)...$_C_DF\n"

AVAILABLE_BRANCHES=$(curl -s 'https://github.com/LineageOS/android_device_samsung_gts4lv/branches' | sed -nE '/branch="/p' | sed 's/^[ \t]*branch="//g' | sed 's/"//g' | sort -r)
total_versions=0
i=0
for v in $AVAILABLE_BRANCHES; do
    printf "    $_C_GR%-4s$_C_OR%-11s$_C_DF\n" "[$(($i + 1))]" "$v"
    ((i++))
    ((total_versions++))
done
echo

read -p "$_M_SUCCESS Select$_C_BL lineage$_C_DF$_C_GR version$_C_DF "$'(\033[36m1-'$total_versions$'\033[0m): ' lineage_version
while [[ !("$lineage_version" =~ ^[0-9]+$) || $lineage_version -lt 1 || $lineage_version -gt $total_versions ]]; do
    echo -en $'\033[1A\033[0K'
    read -p "$_M_SUCCESS Select$_C_BL lineage$_C_DF$_C_GR version$_C_DF "$'(\033[36m1-'$total_versions$'\033[0m): ' lineage_version
done

LINEAGE_VERSION=$(echo $AVAILABLE_BRANCHES | cut -d " " -f $lineage_version)

aaos=-1
if [[ $DEVICE_CODENAME == "gts4lv" || $DEVICE_CODENAME == "gta4xlwifi" ]]; then
    aaos=1
    read -p "$_M_QUESTION Would you like to build$_C_OR AAOS$_C_DF for the chosen target as well? "$'(\033[36my\033[0m/\033[31mN\033[0m): ' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || aaos=0
fi

echo -e "\n$_M_MSG Establishing a build environment...$_C_DF\n"

# Install packages
echo -e "$_M_SUCCESS The following packages will be installed:"

PACKAGES="bc bison build-essential curl flex fontconfig g++-multilib gcc-multilib git-core gnupg gperf lib32ncurses5-dev lib32readline-dev lib32z-dev lib32z1-dev libc6-dev-i386 libelf-dev libgl1-mesa-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libx11-dev libxml2 libxml2-utils lzop rsync schedtool squashfs-tools unzip x11proto-core-dev xsltproc zip zlib1g-dev"

i=0
for p in $PACKAGES; do
    if [[ "$(( $i % 2 ))" -eq 0 ]]; then
        echo
    fi
    # echo -ne "\t• $p\t\t"
    printf "    • %-18s" "$p"
    ((i++))
done
echo -e "\n"

read -p "$_M_SUCCESS$_C_OR Enter$_C_DF to continue... " installation_confirm
while [[ $installation_confirm != "" ]]; do
    echo -en $'\033[1A\033[0K'
    read -p "$_M_SUCCESS$_C_OR Enter$_C_DF to continue... " installation_confirm
done
echo

#sudo apt-get update
#sudo apt-get install $PACKAGES -yq
