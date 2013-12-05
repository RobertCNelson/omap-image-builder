Scripts to support customized image generation for many arm systems

BeagleBoard branch:
------------

    git clone git://github.com/beagleboard/image-builder.git

Images:

    ./beagleboard.org_image.sh
    http://beagleboard.org/source

Flasher:
    sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-debian-7.2-2013-11-21 --uboot bone --beagleboard.org-production --bbb-flasher
    xz -z -7 -v BBB-eMMC-flasher-debian-7.2-2013-11-21-2gb.img

4GB, microSD:
    sudo ./setup_sdcard.sh --img-4gb BBB-debian-7.2-2013-11-26 --uboot bone --beagleboard.org-production
    xz -z -7 -v BBB-debian-7.2-2013-11-21-4gb.img

Master branch:
------------

    git clone git://github.com/RobertCNelson/omap-image-builder

Images:

    ./eewiki_base_image.sh
    ./eewiki_barefs_image.sh
    http://eewiki.net/display/linuxonarm/Home

    ./rcn-ee_image.sh
    http://elinux.org/BeagleBoardUbuntu#Demo_Image
    http://elinux.org/BeagleBoardDebian#Demo_Image

MachineKit:
------------

Branch:

    git clone -b config-hooks https://github.com/cdsteinkuehler/omap-image-builder

Images:

    http://bb-lcnc.blogspot.com/p/machinekit_16.html

Maintainer hints (aka me):

    git pull --no-edit https://github.com/cdsteinkuehler/omap-image-builder MachineKit
