SUMMARY = "Partition table and disk geometry handling utility"
DESCRIPTION = "blkpg-part creates, resizes and deletes partitions on the fly \
               without writing back the changes to the partition table."
HOMEPAGE = "https://github.com/gportay/blkpg-part"
BUGTRACKER = "https://github.com/gportay/blkpg-part/issues"
LICENSE = "LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1803fa9c2c3ce8cb06b4861d75310742"

SRCREV = "5a4ec5f53ed904b37fba03f3797fbe2af3077f8d"
SRC_URI = "git://git@github.com/gportay/blkpg-part.git;protocol=ssh;branch=master"

S = "${WORKDIR}/git"

do_install() {
	install -d ${D}${sbindir}/
	install -m 755 ${B}/blkpg-part ${D}${sbindir}/
}
