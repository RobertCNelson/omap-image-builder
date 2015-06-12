#!/bin/bash

files () {

elinux:
7ba516ca94c64df8b47fe92069a7ffd9  2015-06-11/flasher/BBB-eMMC-flasher-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
14c55b439a80bb969fde23f4aba1782e  2015-06-11/flasher/BBB-eMMC-flasher-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz
4a810366e1114383eb78222f6c798d97  2015-06-11/microsd/bb-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
3866d5e70105d497b4670130103da004  2015-06-11/microsd/bb-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz
707e5f81769d4068056490638c109f62  2015-06-11/microsd/bbx15-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
497dbf6cae9af736ff9767064931addb  2015-06-11/microsd/bbx15-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz
e5cc1d93a6bbdfcc80ba55d39b1338ca  2015-06-11/microsd/bbxm-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
b0d37bfe6ac4e4fdd7541c7359066b54  2015-06-11/microsd/bbxm-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz
5699c2923e3eca666a8152034bbd4dbb  2015-06-11/microsd/bone-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
4981f58f351af887346dc4d05417a42a  2015-06-11/microsd/bone-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz
de03e2c524a99c51811dd8a7bb8d5fed  2015-06-11/microsd/omap5-uevm-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
1ec247e6c0d99306785b2b24b6aa64f6  2015-06-11/microsd/omap5-uevm-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz
}

html_start () {
	echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" > beta
	echo "<html xmlns=\"http://www.w3.org/1999/xhtml\">" >> beta
	echo " <head>" >> beta
	echo "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />" >> beta
	echo "  <title>beta</title>" >> beta
	echo " </head>" >> beta
	echo " <body>" >> beta
	echo "" >> beta
}

html_middle () {
	echo "<h3>${title}</h3>" >> beta
	echo "<ul class=\"arrow\">" >> beta
	echo "    <li itemscope itemtype=\"http://schema.org/SoftwareApplication\">" >> beta
	echo "        <a itemprop=\"downloadURL\"" >> beta
	echo "         href=\"${downloadURL}\"" >> beta
	echo "        >" >> beta
	echo "            <span itemprop=\"name\">${name}</span>" >> beta
	echo "            (<span itemprop=\"device\">${device}</span> -" >> beta
	echo "            <span itemprop=\"memoryRequirements\">${memoryRequirements}</span>)" >> beta
	echo "            <span itemprop=\"datePublished\">${date}</span>" >> beta
	echo "        </a>" >> beta
	echo "        -" >> beta
	echo "        <a itemprop=\"url\" href=\"${url}\">" >> beta
	echo "            more info" >> beta
	echo "        </a>" >> beta
	echo "        -" >> beta
	echo "        md5: <span itemprop=\"md5sum\">${md5sum}</span>" >> beta
	echo "    </li>" >> beta
	echo "</ul>" >> beta
	echo "" >> beta
}

html_end () {
	echo " </body>" >> beta
	echo "</html>" >> beta
}

html_start

#bb.org release
server="https://rcn-ee.com/rootfs/bb.org/release"
date="2015-03-01"

title="BeagleBone and BeagleBone Black via microSD card"
downloadURL="${server}/${date}/console/bone-debian-7.8-console-armhf-${date}-2gb.img.xz"
name="Debian Wheezy (Console)"
device="BeagleBone, BeagleBone Black"
memoryRequirements="2GB SD"
url="http://beagleboard.org/project/debian"
md5sum="10823cb21e6fc4536ff87605dc50ea6e"
html_middle

#bb.org testing
server="https://rcn-ee.com/rootfs/bb.org/testing"

#md5sum bb.org/testing/2015-06-08/*/bone*.xz
#e47c5c883b46d8e72b99657aa0105db0  bb.org/testing/2015-06-08/console/bone-debian-8.1-console-armhf-2015-06-08-2gb.img.xz
#e92433f52084296dc21d24fae1b70c3d  bb.org/testing/2015-06-08/lxqt-4gb/bone-debian-8.1-lxqt-4gb-armhf-2015-06-08-4gb.img.xz
#31f889ed66418456bff4caa153481ba9  bb.org/testing/2015-06-08/machinekit/bone-debian-7.8-machinekit-armhf-2015-06-08-4gb.img.xz

date="2015-06-08"

title="BeagleBone and BeagleBone Black via microSD card"
downloadURL="${server}/${date}/machinekit/bone-debian-7.8-machinekit-armhf-${date}-4gb.img.xz"
name="(machinekit.io) Machinekit"
device="BeagleBone, BeagleBone Black"
memoryRequirements="4GB SD"
url="http://beagleboard.org/project/debian"
md5sum="31f889ed66418456bff4caa153481ba9"
html_middle

title="BeagleBone and BeagleBone Black via microSD card"
downloadURL="${server}/${date}/console/bone-debian-8.1-console-armhf-${date}-4gb.img.xz"
name="(BETA) Debian 8.1 Console"
device="BeagleBone, BeagleBone Black"
memoryRequirements="4GB SD"
url="http://beagleboard.org/project/debian"
md5sum="e47c5c883b46d8e72b99657aa0105db0"
html_middle

title="BeagleBone and BeagleBone Black via microSD card"
downloadURL="${server}/${date}/lxqt-4gb/bone-debian-8.1-lxqt-4gb-armhf-${date}-4gb.img.xz"
name="(BETA) Debian 8.1 LXQt"
device="BeagleBone, BeagleBone Black"
memoryRequirements="4GB SD"
url="http://beagleboard.org/project/debian"
md5sum="e92433f52084296dc21d24fae1b70c3d"
html_middle

#md5sum bb.org/testing/2015-06-08/*/BBB-eMMC*.xz
#301bcf37e866b22fa8b1ff8b0ece4877  bb.org/testing/2015-06-08/console/BBB-eMMC-flasher-debian-8.1-console-armhf-2015-06-08-2gb.img.xz
#c9b85cfd18d2271027c855073db35328  bb.org/testing/2015-06-08/lxqt-2gb/BBB-eMMC-flasher-debian-8.1-lxqt-2gb-armhf-2015-06-08-2gb.img.xz
#3e74f5e0ebc1ccccfcc8eb9bbb7f3814  bb.org/testing/2015-06-08/lxqt-4gb/BBB-eMMC-flasher-debian-8.1-lxqt-4gb-armhf-2015-06-08-4gb.img.xz

date="2015-06-08"

title="BeagleBone Black (eMMC flasher)"
downloadURL="${server}/${date}/console/BBB-eMMC-flasher-debian-8.1-console-armhf-${date}-2gb.img.xz"
name="(BETA) Debian 8.1 Console (eMMC Flasher)"
device="BeagleBone Black"
memoryRequirements="2GB eMMC"
url="http://beagleboard.org/project/debian"
md5sum="301bcf37e866b22fa8b1ff8b0ece4877"
html_middle

title="BeagleBone Black (eMMC flasher)"
downloadURL="${server}/${date}/lxqt-2gb/BBB-eMMC-flasher-debian-8.1-lxqt-2gb-armhf-${date}-2gb.img.xz"
name="(BETA) Debian 8.1 LXQt (eMMC Flasher)"
device="BeagleBone Black"
memoryRequirements="2GB eMMC"
url="http://beagleboard.org/project/debian"
md5sum="c9b85cfd18d2271027c855073db35328"
html_middle

title="BeagleBone Black (eMMC flasher)"
downloadURL="${server}/${date}/lxqt-4gb/BBB-eMMC-flasher-debian-8.1-lxqt-4gb-armhf-${date}-4gb.img.xz"
name="(BETA) Debian 8.1 LXQt (eMMC Flasher)"
device="BeagleBone Black"
memoryRequirements="4GB eMMC"
url="http://beagleboard.org/project/debian"
md5sum="3e74f5e0ebc1ccccfcc8eb9bbb7f3814"
html_middle

#elinux:
server="https://rcn-ee.com/rootfs"

#md5sum 2015-06-11/microsd/bone-*.xz
#5699c2923e3eca666a8152034bbd4dbb  2015-06-11/microsd/bone-debian-8.1-console-armhf-2015-06-11-2gb.img.xz
#4981f58f351af887346dc4d05417a42a  2015-06-11/microsd/bone-ubuntu-14.04.2-console-armhf-2015-06-11-2gb.img.xz

date="2015-06-11"

title="BeagleBone and BeagleBone Black via microSD card"
downloadURL="${server}/${date}/microsd/bone-debian-8.1-console-armhf-${date}-2gb.img.xz"
name="(elinux.org/BeagleBoardDebian) Debian 8.1"
device="BeagleBone, BeagleBone Black"
memoryRequirements="2GB SD"
url="http://beagleboard.org/project/debian"
md5sum="5699c2923e3eca666a8152034bbd4dbb"
html_middle

title="BeagleBone and BeagleBone Black via microSD card"
downloadURL="${server}/${date}/microsd/bone-ubuntu-14.04.2-console-armhf-${date}-2gb.img.xz"
name="(elinux.org/BeagleBoardUbuntu) Ubuntu 14.04.2"
device="BeagleBone, BeagleBone Black"
memoryRequirements="2GB SD"
url="http://beagleboard.org/project/ubuntu"
md5sum="4981f58f351af887346dc4d05417a42a"
html_middle

html_end
#
