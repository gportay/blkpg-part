################################################################################
#
# blkpg-part
#
################################################################################

BLKPG_PART_VERSION = master
BLKPG_PART_SITE = $(call github,gazoo74,blkpg-part,$(BLKPG_PART_VERSION))
BLKPG_PART_LICENSE = GPL-2.0
BLKPG_PART_LICENSE_FILES = LICENCE

define BLKPG_PART_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define BLKPG_PART_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install PREFIX=$(TARGET_DIR)
endef

$(eval $(generic-package))
