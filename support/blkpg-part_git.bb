LICENSE = "LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1803fa9c2c3ce8cb06b4861d75310742"

SRCREV = "${AUTOREV}"
SRC_URI = "git://git@github.com/gportay/blkpg-part.git;protocol=ssh;branch=master"

S = "${WORKDIR}/git"

do_compile() {
	oe_runmake blkpg-part
}

do_install() {
	install -d ${D}${sbindir}/
	install -m 755 ${S}/blkpg-part ${D}${sbindir}/
}
