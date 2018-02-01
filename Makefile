#
#  Copyright (C) 2018 Savoir-Faire Linux Inc.
#
#  Authors:
#      Gaël PORTAY <gael.portay@savoirfairelinux.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

PREFIX ?= /usr/local
CPPCHECKFLAGS ?=

VERSION ?= $(shell git describe --always --all)

override CFLAGS += -DVERSION_STRING='"$(VERSION)"'

.PHONY: all
all: blkpg-part

.PHONY: install
install:
	install -d $(DESTDIR)$(PREFIX)/sbin/
	install -m 755 blkpg-part $(DESTDIR)$(PREFIX)/sbin/

.PHONY: install-bash-completion
install-bash-completion:
	completionsdir=$$(pkg-config --variable=completionsdir bash-completion); \
	if [ -n "$$completionsdir" ]; then \
		install -d $(DESTDIR)$$completionsdir/; \
		install -m 644 support/bash-completion \
		        $(DESTDIR)$$completionsdir/blkpg-part; \
	fi

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/sbin/blkpg-part
	completionsdir=$$(pkg-config --variable=completionsdir bash-completion); \
	if [ -n "$$completionsdir" ]; then \
		rm -f $(DESTDIR)$$completionsdir/blkpg-part; \
	fi

.PHONY: user-install
user-install:
	$(MAKE) install PREFIX=$$HOME/.local

.PHONY: tests
tests: blkpg-part libmock.so
	@./tests.sh

.PHONY: check
check: override CPPCHECKFLAGS += --enable=all --error-exitcode=1 --std=posix
check: override CPPCHECKFLAGS += -DVERSION_STRING='"$(VERSION)"'
check: blkpg-part.c
	cppcheck $(CPPCHECKFLAGS) $^

.PHONY: clean
clean:
	rm -f blkpg-part libmock.so

LINK.so = $(LINK.o)
lib%.so: override LDFLAGS += -shared

lib%.so: %.o
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@

lib%.so: %.c
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@

COMPILE.i = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -E
%.i: %.c
	$(COMPILE.i) $(OUTPUT_OPTION) $<

