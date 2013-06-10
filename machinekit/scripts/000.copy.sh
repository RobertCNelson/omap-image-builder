#!/bin/sh

# If we have a 'kickstart' image, copy the pre-compiled source tree as a tarball
for SOURCE in linuxcnc xenomai-2.6 ; do

	if [ -d ~/beaglebone.kickstart/home/linuxcnc/${SOURCE} ] ; then
		sudo tar cf ${tempdir}/home/linuxcnc/kickstart.${SOURCE}.tar -C ~/beaglebone.kickstart/home/linuxcnc ${SOURCE}
	fi
done

