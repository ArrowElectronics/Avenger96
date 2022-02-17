FILESEXTRAPATHS_append := "${THISDIR}/linux-stm32mp1-dhsom/files"

SRC_URI += " \
	file://0001-media-uapi-Add-an-entity-type-for-Image-Signal-Proce.patch \
	file://0002-media-bus-uapi-Add-YCrCb-420-media-bus-format-and-rs.patch \
	file://0003-media-i2c-Add-ON-Semiconductor-AP1302-ISP-driver.patch \
	file://0004-media-dt-bindings-media-i2c-Add-bindings-for-AP1302.patch \
	file://0005-arch-arm-boot-dts-Added-dts-overlay-support-for-ap13.patch \
	file://0006-media-i2c-ap1302-Add-support-for-ar0430-in-AP1302-dr.patch \
	file://0007-arch-arm-configs-Enable-AP1302-by-default-for-AV96.patch \
	file://0008-media-i2c-ap1302-Removed-the-unused-control-features.patch \
	file://0009-arch-arm-config-Increased-the-size-of-CMA.patch \
	file://0010-media-i2c-ap1320-Removed-few-more-unused-AP1302-cont.patch \
	file://0011-media-i2c-ap1320-Performance-improvement-for-ar0430-.patch \
	file://0012-media-i2c-ap1320-Add-support-for-arx3a0-sensor-in-ap.patch"
