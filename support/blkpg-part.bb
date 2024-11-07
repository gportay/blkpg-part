LICENSE = "LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRCREV = "${AUTOREV}"
SRC_URI = "git://git@github.com/gportay/blkpg-part.git;protocol=ssh;branch=master"

S = "${WORKDIR}/git"

do_compile() {
	oe_runmake blkpg-part
}

do_install() {
	install -d ${D}${sbindir}/
	install -m 755 blkpg-part ${D}${sbindir}/
}
