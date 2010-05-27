setenv bootcmd 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs console=ttyS2,115200n8 console=tty0 root=/dev/mmcblk0p2 rootwait ro vram=12M omapfb.mode=dvi:1280x720MR-16@60 fixrtc buddy=${buddy} mpurate=${mpurate}
boot

