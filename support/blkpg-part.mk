################################################################################
#
# blkpg-part
#
################################################################################

BLKPG_PART_VERSION = master
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
