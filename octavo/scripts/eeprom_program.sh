#!/bin/sh

echo 24c32 0x50 > /sys/bus/i2c/devices/i2c-0/new_device
cat /opt/eeprom/bbb-eeprom.dump > /sys/bus/i2c/devices/0-0050/0-00500/nvmem
