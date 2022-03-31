# Copyright (C) 2022 Deepak Rathore <deepak.rathore@einfochips.com>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Firmware files for AP1302 ISP camera sensors"

LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += "file://lib/firmware/ap1302_ar0430_fw.bin"
SRC_URI += "file://lib/firmware/ap1302_arx3a0_fw.bin"
SRC_URI += "file://lib/firmware/ap1302_ar1335_fw.bin"

do_install() {
    install -d ${D}${base_libdir}/firmware/
    install -m 755 ${WORKDIR}/lib/firmware/* ${D}${base_libdir}/firmware/
}

FILES_${PN} += "${base_libdir}/firmware/ap1302_ar0430_fw.bin"
FILES_${PN} += "${base_libdir}/firmware/ap1302_arx3a0_fw.bin"
FILES_${PN} += "${base_libdir}/firmware/ap1302_ar1335_fw.bin"
