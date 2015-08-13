eeprom database
------------

BeagleBone Black:

    A5A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 41 |.U3.A335BNLT0A5A|]
    A5B: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 42 |.U3.A335BNLT0A5B|]
    A5C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 43 |.U3.A335BNLT0A5C|]
     A6: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 41 36 |.U3.A335BNLT00A6|]
      C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 30 43 |.U3.A335BNLT000C|]

BeagleBone Green:

      1: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 1a 00 00 00 |.U3.A335BNLT....|]

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

    ./RootStock-NG.sh -c eewiki_minfs_debian_jessie_armel

eewiki.net: Debian Stable (armhf) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_debian_jessie_armhf

eewiki.net: Ubuntu Stable (armhf) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_ubuntu_trusty_armhf

eewiki.net: Debian Stable (armel) barefs:

    ./RootStock-NG.sh -c eewiki_bare_debian_jessie_armel

eewiki.net: Debian Stable (armhf) barefs:

    ./RootStock-NG.sh -c eewiki_bare_debian_jessie_armhf

elinux.org: Debian Images:

    ./RootStock-NG.sh -c rcn-ee_console_debian_jessie_armhf
    ./RootStock-NG.sh -c rcn-ee_console_debian_stretch_armhf
    http://elinux.org/BeagleBoardDebian#Demo_Image

elinux.org: Ubuntu Images:

    ./RootStock-NG.sh -c rcn-ee_console_ubuntu_trusty_armhf
    http://elinux.org/BeagleBoardUbuntu#Demo_Image

Release Process:

    vYEAR.MONTH
    git tag -a v201y.mm -m 'v201y.mm'
    git push origin --tags

MachineKit:
------------

    ./RootStock-NG.sh -c machinekit-debian-wheezy
    http://elinux.org/Beagleboard:BeagleBoneBlack_Debian#BBW.2FBBB_.28All_Revs.29_Machinekit
