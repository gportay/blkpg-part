#
# Copyright 2018,2021,2023-2024 Gaël PORTAY
#                     2023-2024 Rtone.
#                          2021 Collabora Ltd.
#                          2018 Savoir-Faire Linux Inc.
#
# SPDX-License-Identifier: LGPL-2.1-or-later
#

VERSION = 1
PREFIX ?= /usr/local
CPPCHECKFLAGS ?=

override CPPFLAGS += -DVERSION_STRING='"$(VERSION)"'

.PHONY: all
all: blkpg-part

.PHONY: doc
doc: blkpg-part.1.gz

.PHONY: install-all
install-all: install install-doc install-bash-completion

.PHONY: install
install:
	install -D -m 755 blkpg-part $(DESTDIR)$(PREFIX)/sbin/blkpg-part

.PHONY: install-doc
install-doc:
	install -D -m 644 blkpg-part.1.gz $(DESTDIR)$(PREFIX)/share/man/man1/blkpg-part.1.gz

.PHONY: install-bash-completion
install-bash-completion:
	completionsdir=$${BASHCOMPLETIONSDIR:-$$(pkg-config --define-variable=prefix=$(PREFIX) \
	                                                    --variable=completionsdir \
	                                                    bash-completion)}; \
	if [ -n "$$completionsdir" ]; then \
		install -D -m 644 support/bash-completion $(DESTDIR)$$completionsdir/blkpg-part; \
	fi

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/sbin/blkpg-part
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/blkpg-part.1.gz
	completionsdir=$${BASHCOMPLETIONSDIR:-$$(pkg-config --define-variable=prefix=$(PREFIX) \
	                                                    --variable=completionsdir \
	                                                    bash-completion)}; \
	if [ -n "$$completionsdir" ]; then \
		rm -f $(DESTDIR)$$completionsdir/blkpg-part; \
	fi

.PHONY: user-install-all
user-install-all: user-install user-install-doc user-install-bash-completion

user-install user-install-doc user-install-bash-completion user-uninstall:
user-%:
	$(MAKE) $* PREFIX=$$HOME/.local BASHCOMPLETIONSDIR=$$HOME/.local/share/bash-completion/completions

.PHONY: test tests
test tests: blkpg-part libmock.so
	@./tests.bash

.PHONY: check
check: override CPPCHECKFLAGS += --enable=all --error-exitcode=1 --suppress=missingIncludeSystem
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
	gzip -c $< >$@

