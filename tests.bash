#!/bin/bash
#
# Copyright 2018,2021,2023 Gaël PORTAY
#                     2023 Rtone.
#                     2021 Collabora Ltd.
#                     2018 Savoir-Faire Linux Inc.
#
# SPDX-License-Identifier: LGPL-2.1-or-later
#

set -e
set -o pipefail

run() {
	lineno="${BASH_LINENO[0]}"
	test="$*"
	echo -e "\e[1mRunning $test...\e[0m"
}

ok() {
	ok=$((ok+1))
	echo -e "\e[1m$test: \e[32m[OK]\e[0m"
}

ko() {
	ko=$((ko+1))
	echo -e "\e[1m$test: \e[31m[KO]\e[0m"
	reports+=("$test at line \e[1m$lineno \e[31mhas failed\e[0m!")
	if [[ $EXIT_ON_ERROR ]]
	then
		exit 1
	fi
}

result() {
	exitcode="$?"
	trap - 0

	echo -e "\e[1mTest report:\e[0m"
	for report in "${reports[@]}"
	do
		echo -e "$report" >&2
	done

	if [[ $ok ]]
	then
		echo -e "\e[1m\e[32m$ok test(s) succeed!\e[0m"
	fi

	if [[ $fix ]]
	then
		echo -e "\e[1m\e[34m$fix test(s) fixed!\e[0m" >&2
	fi

	if [[ $bug ]]
	then
		echo -e "\e[1mWarning: \e[33m$bug test(s) bug!\e[0m" >&2
	fi

	if [[ $ko ]]
	then
		echo -e "\e[1mError: \e[31m$ko test(s) failed!\e[0m" >&2
	fi

	if [[ $exitcode -ne 0 ]] && [[ $ko ]]
	then
		echo -e "\e[1;31mExited!\e[0m" >&2
	elif [[ $exitcode -eq 0 ]] && [[ $ko ]]
	then
		exit 1
	fi

	exit "$exitcode"
}

PATH="$PWD:$PATH"
trap result 0 SIGINT

blkpg-part() {
	LD_PRELOAD="$PWD/libmock.so" ./blkpg-part "$@"
}

blkpgtab-generator() {
	./blkpgtab-generator "$@"
}

run "Test add operation"
if cat <<EOF | diff - <(blkpg-part add /dev/sda 100 0 512)
open_filename="/dev/sda"
open_flags=0x2
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

run "blkpgtab-generator: test without argument"
if ! blkpgtab-generator
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with kernel-command-line parameter blkpg=no"
if install -d "$PWD/.tests-blkpg-$$/proc" && \
   echo "blkpg=no" >"$PWD/.tests-blkpg-$$/proc/cmdline" && \
   install -D -m644 "support/blkpgtab" "$PWD/.tests-blkpg-$$/etc/blkpgtab" && \
   ROOT="$PWD/.tests-blkpg-$$" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with kernel-command-line parameter blkpg"
if install -d "$PWD/.tests-blkpg-$$/proc" && \
   echo "blkpg" >"$PWD/.tests-blkpg-$$/proc/cmdline" && \
   install -D -m644 "support/blkpgtab" "$PWD/.tests-blkpg-$$/etc/blkpgtab" && \
   ROOT="$PWD/.tests-blkpg-$$" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with kernel-command-line parameter blkpg=yes"
if install -d "$PWD/.tests-blkpg-$$/proc" && \
   echo "blkpg=yes" >"$PWD/.tests-blkpg-$$/proc/cmdline" && \
   install -D -m644 "support/blkpgtab" "$PWD/.tests-blkpg-$$/etc/blkpgtab" && \
   ROOT="$PWD/.tests-blkpg-$$" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test without kernel-command-line parameter blkpg"
if install -d "$PWD/.tests-blkpg-$$/proc" && \
   echo >"$PWD/.tests-blkpg-$$/proc/cmdline" && \
   install -D -m644 "support/blkpgtab" "$PWD/.tests-blkpg-$$/etc/blkpgtab" && \
   ROOT="$PWD/.tests-blkpg-$$" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with SYSTEMD_PROC_CMDLINE=blkpg=no"
if ROOT="$PWD/.tests-blkpg-$$" \
   SYSTEMD_PROC_CMDLINE="blkpg=no" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with SYSTEMD_PROC_CMDLINE=blkpg"
if ROOT="$PWD/.tests-blkpg-$$" \
   SYSTEMD_PROC_CMDLINE="blkpg" \
   SYSTEMD_BLKPGTAB="$PWD/support/blkpgtab" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with SYSTEMD_PROC_CMDLINE=blkpg=yes"
if ROOT="$PWD/.tests-blkpg-$$" \
   SYSTEMD_PROC_CMDLINE="blkpg=yes" \
   SYSTEMD_BLKPGTAB="$PWD/support/blkpgtab" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with SYSTEMD_PROC_CMDLINE="
if ROOT="$PWD/.tests-blkpg-$$" \
   SYSTEMD_PROC_CMDLINE="" \
   SYSTEMD_BLKPGTAB="$PWD/support/blkpgtab" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test without /etc/blkpgtab file"
if rm -Rf "$PWD/.tests-blkpg-$$/etc/blkpgtab" && \
   ROOT="$PWD/.tests-blkpg-$$" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   ! test -d "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo

run "blkpgtab-generator: test with without /etc/blkpgtab file and SYSTEMD_BLKPGTAB=$PWD/support/blkpgtab"
if rm -Rf "$PWD/.tests-blkpg-$$/etc/blkpgtab" && \
   ROOT="$PWD/.tests-blkpg-$$" \
   SYSTEMD_BLKPGTAB="$PWD/support/blkpgtab" \
   blkpgtab-generator "/run/systemd/generator" "/run/systemd/generator.early" "/run/systemd/generator.late" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p100.service" && \
   test -e "$PWD/.tests-blkpg-$$/run/systemd/generator/blkpg-dev-mmcblk0p101.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p100.service" && \
   test -L "$PWD/.tests-blkpg-$$/run/systemd/generator/sysinit.target.wants/blkpg-dev-mmcblk0p101.service" && \
   rm -Rf "$PWD/.tests-blkpg-$$/"
then
	ok
else
	ko
fi
echo
