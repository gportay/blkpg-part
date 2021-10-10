LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRCREV = "${AUTOREV}"
SRC_URI = "git://git@github.com/gportay/${PN}.git;protocol=ssh"

S = "${WORKDIR}/git"

do_compile() {
	oe_runmake ${PN}
}

do_install() {
	install -d ${D}${sbindir}/
	install -m 755 ${PN} ${D}${sbindir}/
}
