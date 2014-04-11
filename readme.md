Scripts to support customized image generation for many arm systems

BeagleBoard branch:
------------

    git clone https://github.com/beagleboard/image-builder.git

Images:

    ./beagleboard.org_image.sh
    http://beagleboard.org/source

Flasher:

    sudo ./setup_sdcard.sh --img BBB-eMMC-flasher-debian-7.X-YYYY-MM-DD --uboot bone \
    --beagleboard.org-production --bbb-flasher --boot_label BEAGLE_BONE \
    --rootfs_label eMMC-Flasher --enable-systemd

    xz -z -7 -v BBB-eMMC-flasher-debian-7.X-YYYY-MM-DD-2gb.img

2GB, microSD:

    sudo ./setup_sdcard.sh --img bone-debian-7.X-YYYY-MM-DD --uboot bone \
    --beagleboard.org-production --boot_label BEAGLE_BONE --enable-systemd

    xz -z -7 -v bone-debian-7.X-YYYY-MM-DD-2gb.img

Bug Tracker:

    http://bugs.elinux.org/projects/debian-image-releases

Release Process:

    bb.org-vYYYY.MM.DD
    git tag -a bb.org-vYYYY.MM.DD -m 'bb.org-vYYYY.MM.DD'
    git push origin --tags

Master branch:
------------

    git clone https://github.com/RobertCNelson/omap-image-builder

Images:

    ./eewiki_base_image.sh
    ./eewiki_barefs_image.sh
    http://eewiki.net/display/linuxonarm/Home

    ./rcn-ee_image.sh
    http://elinux.org/BeagleBoardUbuntu#Demo_Image
    http://elinux.org/BeagleBoardDebian#Demo_Image

Release Process:

    vYEAR.MONTH
    git tag -a v2014.01 -m 'v2014.01'
    git push origin --tags

MachineKit:
------------

Branch:

    git clone -b config-hooks https://github.com/cdsteinkuehler/omap-image-builder

Images:

    http://bb-lcnc.blogspot.com/p/machinekit_16.html

Maintainer hints (aka me):

    git pull --no-edit https://github.com/cdsteinkuehler/omap-image-builder MachineKit
