Scripts to support customized image generation for many arm systems

BeagleBoard branch:
------------

    git clone https://github.com/beagleboard/image-builder.git

Images:

    ./beagleboard.org_image.sh
    http://beagleboard.org/source

Flasher:

    sudo ./setup_sdcard.sh --img-4gb BBB-eMMC-flasher-debian-7.X-201Y-MM-DD \
    --dtb beaglebone --beagleboard.org-production --boot_label BEAGLEBONE \
    --rootfs_label eMMC-Flasher --enable-systemd --bbb-flasher \
    --bbb-old-bootloader-in-emmc

    xz -z -8 -v BBB-eMMC-flasher-debian-7.X-201Y-MM-DD-4gb.img

2GB, microSD:

    sudo ./setup_sdcard.sh --img-2gb bone-debian-7.X-201Y-MM-DD --dtb beaglebone \
    --beagleboard.org-production --boot_label BEAGLEBONE --enable-systemd \
    --bbb-old-bootloader-in-emmc

    xz -z -8 -v bone-debian-7.X-201Y-MM-DD-2gb.img

Bug Tracker:

    http://bugs.elinux.org/projects/debian-image-releases

Release Process:

    bb.org-v201Y.MM.DD
    git tag -a bb.org-v201Y.MM.DD -m 'bb.org-v201Y.MM.DD'
    git push origin --tags

Master branch:
------------

    git clone https://github.com/RobertCNelson/omap-image-builder

eewiki.net: Debian Stable (armel) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_debian_stable_armel

eewiki.net: Debian Stable (armhf) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_debian_stable_armhf

eewiki.net: Ubuntu Stable (armhf) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_ubuntu_stable_armhf

eewiki.net: Debian Stable (armel) barefs:

    ./RootStock-NG.sh -c eewiki_bare_debian_stable_armel

eewiki.net: Debian Stable (armhf) barefs:

    ./RootStock-NG.sh -c eewiki_bare_debian_stable_armhf

elinux.org: Debian Images:

    ./RootStock-NG.sh -c rcn-ee_console_debian_stable_armhf
    ./RootStock-NG.sh -c rcn-ee_console_debian_testing_armhf
    http://elinux.org/BeagleBoardDebian#Demo_Image

elinux.org: Ubuntu Images:

    ./RootStock-NG.sh -c rcn-ee_console_ubuntu_stable_armhf
    http://elinux.org/BeagleBoardUbuntu#Demo_Image

Release Process:

    vYEAR.MONTH
    git tag -a v201y.mm -m 'v201y.mm'
    git push origin --tags

MachineKit:
------------

Branch:

    git clone -b config-hooks https://github.com/cdsteinkuehler/omap-image-builder

Images:

    http://bb-lcnc.blogspot.com/p/machinekit_16.html

Maintainer hints (aka me):

    git pull --no-edit https://github.com/cdsteinkuehler/omap-image-builder MachineKit
