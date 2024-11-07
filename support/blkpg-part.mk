################################################################################
#
# blkpg-part
#
################################################################################

BLKPG_PART_VERSION = 5a4ec5f53ed904b37fba03f3797fbe2af3077f8d
BLKPG_PART_SITE = $(call github,gportay,blkpg-part,$(BLKPG_PART_VERSION))
BLKPG_PART_LICENSE = LGPL-2.1-or-later
BLKPG_PART_LICENSE_FILES = LICENSE

define BLKPG_PART_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define BLKPG_PART_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install PREFIX=$(TARGET_DIR)
endef

$(eval $(generic-package))
