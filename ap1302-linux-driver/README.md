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
3 functions will be registered into the sysfs interface:
- dump
- write_reg16
- write_reg32

These are usually accessible under /sys/devices/platform/soc/40013000.i2c/i2c-1/1-003d/
| Function      | Description |
| ----------- | ----------- |
| dump \<addr\> \<len\> | dumps I2C registers to kernel log |
| write_reag16 \<addr\> \<value\> | write 16-bit value to I2C register |
| write_reag32 \<addr\> \<value\> | write 32-bit value to I2C register |

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


