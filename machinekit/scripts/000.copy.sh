#!/bin/sh

# If we have a 'kickstart' image, copy the pre-compiled source tree as a tarball
if [ -d ~/beaglebone.kickstart/home/linuxcnc ] ; then
	sudo tar cvf ${tempdir}/home/linuxcnc/kickstart.tar -C ~/beaglebone.kickstart/home/linuxcnc linuxcnc xenomai-2.6 >/dev/null
fi

