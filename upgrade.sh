#!/bin/bash
set -eux

# upgrade all the packages.
yum upgrade -y

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
