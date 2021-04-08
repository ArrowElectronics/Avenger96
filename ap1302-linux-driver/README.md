#### ap1302.ko Linux kernel driver
meta-av96 recipe for the linux kernel:
&nbsp;&nbsp;&nbsp;&nbsp;[meta-av96/recipes-bsp/linux-stm32mp/linux-stm32mp_%.bbappend](https://github.com/dh-electronics/meta-av96/blob/dunfell/recipes-bsp/linux-stm32mp/linux-stm32mp_%25.bbappend)

patch file for the ap1302.ko driver:
&nbsp;&nbsp;&nbsp;&nbsp;[meta-av96/recipes-bsp/linux-stm32mp/files/0001-linux-ap1302.patch](https://github.com/dh-electronics/meta-av96/blob/dunfell/recipes-bsp/linux-stm32mp/files/0001-linux-ap1302.patch)

Files affected by the patch:
- drivers/media/i2c/ap1302.c
- drivers/media/i2c/Kconfig
- drivers/media/i2c/Makefile
<br/>

ap1302.ko implements an "i2c_driver":
```
static const struct of_device_id ap1302_dt_ids[] = {
	{ .compatible = "on,ap1302" },
};
static struct i2c_driver ap1302_i2c_driver = {
	.driver = {
		.name  = "ap1302",
		.of_match_table	= ap1302_dt_ids,
	},
	.id_table = ap1302_id,
	.probe    = ap1302_probe,
	.remove   = ap1302_remove,
};
```
<br/>

Linux will pair the driver with the devicetree entry based on *ap1302_dt_ids[0].compatible* . I2C subsystem will then call *ap1302_i2c_driver.probe* function.

<br/>
<br/>

##### ap1302_probe() 
The main routine for initializing the driver. It checks if the AP1302 ISP is present on the I2C bus but doesn't initialize it. It merely initializes and registers *my_sensors->sd* which is of type *v4l2_subdev*. It also registers controls for the V4L2 device.
Additionally it initializes the *sysf*s interface.

<br/>
<br/>

##### sysfs interface
3 helper functions will be registered into the sysfs interface:
- dump
- write_reg16
- write_reg32

These are usually accessible under /sys/devices/platform/soc/40013000.i2c/i2c-1/1-003d/
| Function      | Description |
| ----------- | ----------- |
| dump \<addr\> \<len\> | dumps I2C registers to kernel log |
| write_reag16 \<addr\> \<value\> | write 16-bit value to I2C register |
| write_reag32 \<addr\> \<value\> | write 32-bit value to I2C register |

These functions are available only when the device is powered on (usually when streaming).

<br/>
<br/>

##### ap1302_s_power
V4L2 subdev function, called to power the device on or off.

<br/>
<br/>

##### ap1302_s_stream
V4L2 subdev function, called to start the video stream. It first downloads the ISP firmware by calling *ap1302_fw_loop*. After ISP firmware has started it sets controls (mode, format, exposure, ...). As last it will call *ap1302_set_fps*.

<br/>
<br/>

##### ap1302_set_fps
Internal helper function for setting the framerate. Additionally it fixes color order on MIPI bus. By default AP1302 ISP sends MIPI packets with invalid color order in RGB565 and in YUV422 formats.  *ap1302_set_fps* fixes the color order.


<br/>
<br/>

####  AP1302 ISP firmware
AP1302 ISP firmware comes in .XML format from the manufacturer. See [ap1302_xml_tools](https://github.com/ArrowElectronics/Avenger96/tree/dev-tools/ap1302_xml_tools) and xml2bin.py.

<br/>

##### Firmware files
Binary firmware files are placed in /lib/firmware/ap1302. During initialization *ap1302_probe* calls *ap1302_download_fw* which loads these firmware files into memory via Linux *request_firmware API*. Names of binary firmware files are currently hardcoded in *AP1302_FW_TEST* and *AP1302_FW_NORMAL*.

<br/>

##### ap1302_fw_loop

Firmware download is a multi-stage process and is documented in the AP1302 datasheet.

 1. Download first part of "*bootdata*" array. The number of bytes to be downloaded is specified by *ap1302_fw_data.pll_init_size*.
 2. Set up PLL by writing I2C registers and wait for the PLL to lock.
 3. Download the rest of "*bootdata*" array, wait for the firmware to start and calculate checksum, verify checksum against *ap1302_fw_data.chksum*.
 
<br/>

##### AP1302 debug console
AP1302 *debug console* feature is documented in *AN9431/D - AP1302 Developer guide*. The *debug console* is a 512-byte array inside the AP1302 address space which is used as a rolling buffer for debug messages. If both *AP1302_DBG_CONSOLE_OUTPUT* and *AP1302_TRACE_LOG* in **ap1302.c** are set to 1 the driver keeps on reading the 512-byte rolling buffer periodically and prints the new debug messages in the kernel debug console.
  
<br/>

#####  ap1302_trace_log
If AP1302 *debug console* is enabled *ap1302_trace_log*  will be called regularly by *ap1302_fw_loop* during firmware download. It reads the new state of the 512-byte rolling buffer, compares it with the previous state and tries to figure out what new messages were written by the AP1302 firmware. As the rolling buffer gets overwritten in the background by the firmware *ap1302_trace_log* may not always find the starting end ending point of new messages inside the buffer. But most of the time it prints acceptable results in the kernel log.

<br/>

##### Changing PLL settings
Current PLL settings can be found in *ap1302_fw_pll_320M[]* array. These values can be calculated by DevWareX application. Required steps for calculating PLL registers when DevWareX with the given image sensor board and the AP1302 board is already running:

 - in "Toolbar" menu enable the MIPI toolbar
 - show Log window and select "Enable Log"
 - in MIPI toolbar select "Clocks Wizzard"
 - leave the input clock at 48MHz
 - set MIPI speed to 320Mbps
 - from the initialization methods select "During Initialization" and press OK
 
 DevWareX will re-initialize the ISP. The Log window will capture the initialization sequence and PLL registers will be available in the PLL init phase.

<br/>

####  Supported modes
Supported modes (frame sizes) are stored in *ap1302_mode_data* array. Modes will be reported to V4L2 subsystem during subsequent calls to *ap1302_enum_frame_size*. Currently supported modes:

&nbsp;&nbsp;&nbsp;&nbsp;320 x 240, 640 x 480, 1024 x 576, 1280 x 720, 1920 x 1080, 4160 x 3120

<br/>

####  Supported formats
Supported media formats are stored in *ap1302_formats* array. Formats will be reported to V4L2 subsystem during subsequent calls to *ap1302_try_fmt_internal*. Currently supported formats:

&nbsp;&nbsp;&nbsp;&nbsp;MEDIA_BUS_FMT_RGB565_2X8_LE, MEDIA_BUS_FMT_YUYV8_2X8

<br/>

####  Supported controls
The driver supports currently the following controls:

&nbsp;&nbsp;&nbsp;&nbsp;test pattern, horizontal flip, vertical flip, link frequency, auto/manual exposure, manual exposure value.
These controls will be registered by *ap1302_init_controls* during driver initialization. Because of calibration issues of the AR1337 firmware auto exposure is turned off by default and an experimental manual exposure value is used. Auto exposure can be turned on again by
```
# v4l2-ctl --set-ctrl auto_exposure=0
```
any time when streaming is on or off.

<br/>

####  Suggested improvements
Current **ap1302.ko** driver was tailored to support the AR1337 image sensor and the suitable firmware. It should be made more flexible to load image sensor type from the device tree and initialize firmware accordingly.
