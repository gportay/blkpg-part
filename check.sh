#!/bin/bash
#
# Copyright 2018 Savoir-Faire Linux Inc.
#
# SPDX-License-Identifier: LGPL-2.1-or-later
#

CPPCHECKFLAGS+=" -I/usr/include"
export CPPCHECKFLAGS

install="$(cc -print-search-dirs | sed -n '/^install: /s,^install: ,,p')"
if [ -n "$install" ] && [ -d "$install/include" ]; then
	CPPCHECKFLAGS+=" -I$install/include"
	export CPPCHECKFLAGS
fi

make check
