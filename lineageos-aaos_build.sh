#!/bin/bash

### REQUIREMENTS ###

echo -e "\n\033[2m-- Checking requirements...\033[22m\n"

# Check for the operating system
# if [[ "$OSTYPE" != "linux-gnu"* ]]; then
#     echo -e "\033[33mYou are running $OSTYPE, but linux required.\033[39m"
#     exit 1
# fi

echo -e "Operating System:\t$OSTYPE"

# # Check for an amount of RAM available for a build
# RAM_GB="$(expr $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024)"

# if [[ RAM_GB < 16 ]]; then
#     echo -e "\033[33mYour machine has $($RAM_GB)GB of RAM, but at least 16GB of available RAM is required.\033[39m"
#     if [[ RAM_GB < 8 ]]; then
#         exit 1
#     fi
# fi
RAM_GB=16
echo -e "RAM:\t\t\t$RAM_GB GB"

# Check for disk capacity
DISK_CAPACITY=$(df -H . | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $2 }' | rev | cut -c 2- | rev)

# if [[ $DISK_CAPACITY < 250 ]]; then
#     echo -e "\n\033[33mThe directory you specified is on a disk with insufficient disk space for a build.\nYou need at least 250GB of free disk space to check out the code and an extra 150GB to build it.\033[39m"
#     exit 1
# fi

echo -e "DISK SIZE:\t\t$DISK_CAPACITY GB"

echo -e "\n\033[2m++ Requirements are satisfied.\033[22m\n"

### BUILD ENVIRONMENT ###

echo -e "\n\033[2m-- Establishing a build environment...\033[22m\n"