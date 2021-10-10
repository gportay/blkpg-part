#!/bin/bash
#
# Copyright 2018 Savoir-Faire Linux Inc.
#
# SPDX-License-Identifier: GPL-2.0
#

set -e
set -o pipefail

run() {
	id=$((id+1))
	test="#$id: $@"
	echo -e "\e[1mRunning $test...\e[0m"
}

ok() {
	ok=$((ok+1))
	echo -e "\e[1m$test: \e[32m[OK]\e[0m"
}

ko() {
	ko=$((ko+1))
	echo -e "\e[1m$test: \e[31m[KO]\e[0m"
}

result() {
	if [ -n "$ok" ]; then
		echo -e "\e[1m\e[32m$ok test(s) succeed!\e[0m"
	fi

	if [ -n "$fix" ]; then
		echo -e "\e[1m\e[34m$fix test(s) fixed!\e[0m" >&2
	fi

	if [ -n "$bug" ]; then
		echo -e "\e[1mWarning: \e[33m$bug test(s) bug!\e[0m" >&2
	fi

	if [ -n "$ko" ]; then
		echo -e "\e[1mError: \e[31m$ko test(s) failed!\e[0m" >&2
		exit 1
	fi
}

PATH="$PWD:$PATH"
trap result 0

blkpg-part() {
	LD_PRELOAD="$PWD/libmock.so" ./blkpg-part "$@"
}

run "Test add operation"
if cat <<EOF | diff - <(blkpg-part add /dev/sda 100 0 512)
open_filename="/dev/sda"
open_flags=0x2
open_mode=0x0
ioctl_fd=127
ioctl_req=4713
ioctl_arg1_op=0x1
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_op=0x1
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_data_start=0
ioctl_arg1_data_length=512
ioctl_arg1_data_pno=100
ioctl_arg1_data_devname="/dev/sda"
ioctl_arg1_data_volname=""
close_fd=127
EOF
then
	ok
else
	ko
fi
echo

run "Test resize operation"
if cat <<EOF | diff - <(blkpg-part resize /dev/sda 100 0 512)
open_filename="/dev/sda"
open_flags=0x2
open_mode=0x0
ioctl_fd=127
ioctl_req=4713
ioctl_arg1_op=0x3
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_op=0x3
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_data_start=0
ioctl_arg1_data_length=512
ioctl_arg1_data_pno=100
ioctl_arg1_data_devname="/dev/sda"
ioctl_arg1_data_volname=""
close_fd=127
EOF
then
	ok
else
	ko
fi
echo

run "Test delete operation"
if cat <<EOF | diff - <(blkpg-part delete /dev/sda 100)
open_filename="/dev/sda"
open_flags=0x2
open_mode=0x0
ioctl_fd=127
ioctl_req=4713
ioctl_arg1_op=0x2
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_op=0x2
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_data_start=0
ioctl_arg1_data_length=0
ioctl_arg1_data_pno=100
ioctl_arg1_data_devname="/dev/sda"
ioctl_arg1_data_volname=""
close_fd=127
EOF
then
	ok
else
	ko
fi
echo

run "Test --volume-name option"
if cat <<EOF | diff - <(blkpg-part --volume-name MBR add /dev/sda 100 0 512)
open_filename="/dev/sda"
open_flags=0x2
open_mode=0x0
ioctl_fd=127
ioctl_req=4713
ioctl_arg1_op=0x1
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_op=0x1
ioctl_arg1_flags=0x0
ioctl_arg1_datalen=152
ioctl_arg1_data_start=0
ioctl_arg1_data_length=512
ioctl_arg1_data_pno=100
ioctl_arg1_data_devname="/dev/sda"
ioctl_arg1_data_volname="MBR"
close_fd=127
EOF
then
	ok
else
	ko
fi
echo

