#!/bin/bash
#
# Copyright 2018 Savoir-Faire Linux Inc.
#
# SPDX-License-Identifier: GPL-2.0
#

CPPCHECKFLAGS+=" -I/usr/include"
export CPPCHECKFLAGS

install="$(cc -print-search-dirs | sed -n '/^install: /s,^install: ,,p')"
if [ -n "$install" ] && [ -d "$install/include" ]; then
	CPPCHECKFLAGS+=" -I$install/include"
	export CPPCHECKFLAGS
fi

make check
