#
# Copyright 2018 Savoir-Faire Linux Inc.
#
# SPDX-License-Identifier: GPL-2.0-only
#

PREFIX ?= /usr/local
CPPCHECKFLAGS ?=

VERSION ?= $(shell git describe --always --all)

override CFLAGS += -DVERSION_STRING='"$(VERSION)"'

.PHONY: all
all: blkpg-part

.PHONY: doc
doc: blkpg-part.1.gz

.PHONY: install
install:
	install -d $(DESTDIR)$(PREFIX)/sbin/
	install -m 755 blkpg-part $(DESTDIR)$(PREFIX)/sbin/

.PHONY: install-doc
install-doc:
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	install -m 644 blkpg-part.1.gz $(DESTDIR)$(PREFIX)/share/man/man1/

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
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/blkpg-part.1.gz
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

%.1: %.1.adoc
	asciidoctor -b manpage -o $@ $<

%.gz: %
	gzip -c $^ >$@

