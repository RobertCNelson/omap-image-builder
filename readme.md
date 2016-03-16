eeprom database
------------

BeagleBoard.org BeagleBone (original bone/white):

      A4: [aa 55 33 ee 41 33 33 35  42 4f 4e 45 30 30 41 34 |.U3.A335BONE00A4|]
      A5: [aa 55 33 ee 41 33 33 35  42 4f 4e 45 30 30 41 35 |.U3.A335BONE00A5|]
      A6: [aa 55 33 ee 41 33 33 35  42 4f 4e 45 30 30 41 36 |.U3.A335BONE00A6|]
     A6A: [aa 55 33 ee 41 33 33 35  42 4f 4e 45 30 41 36 41 |.U3.A335BONE0A6A|]
     A6B: [aa 55 33 ee 41 33 33 35  42 4f 4e 45 30 41 36 42 |.U3.A335BONE0A6B|]
       B: [aa 55 33 ee 41 33 33 35  42 4f 4e 45 30 30 30 42 |.U3.A335BONE000B|]

BeagleBoard.org or Element14 BeagleBone Black:

     A5A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 41 |.U3.A335BNLT0A5A|]
     A5B: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 42 |.U3.A335BNLT0A5B|]
     A5C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 43 |.U3.A335BNLT0A5C|]
      A6: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 41 36 |.U3.A335BNLT00A6|]
       C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 30 43 |.U3.A335BNLT000C|]

Element14 BeagleBone Black (newer rev C?):

       C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 43 30 |.U3.A335BNLT00C0|]

BeagleBoard.org BeagleBone Blue:

      A0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 42 4c 41 30 |.U3.A335BNLTBLA0|]

SeeedStudio BeagleBone Green:

      1A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 1a 00 00 00 |.U3.A335BNLT....|]
     W1A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 47 57 31 41 |.U3.A335BNLTGW1A|]

Arrow BeagleBone Black Industrial:

      A0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 41 49 41 30 |.U3.A335BNLTAIA0|]

Element14 BeagleBone Black Industrial:

      A0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 45 49 41 30 |.U3.A335BNLTEIA0|]

SanCloud BeagleBone Enhanced:

       A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 53 45 30 41 |.U3.A335BNLTSE0A|]

MENTOREL uSomIQ BBB:

       6: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 4d 45 30 41 |.U3.A335BNLTME06|]

Embest replica?:

          [aa 55 33 ee 41 33 33 35  42 4e 4c 54 74 0a 75 65 |.U3.A335BNLTt.ue|]

GHI OSD3358 Dev Board:

     0.1: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 47 48 30 31 |.U3.A335BNLTGH01|]

Scripts to support customized image generation for many arm systems

BeagleBoard branch:
------------

    git clone https://github.com/beagleboard/image-builder.git

Images:

    ./beagleboard.org_image.sh
    http://beagleboard.org/source

Flasher:

    sudo ./setup_sdcard.sh --img-4gb BBB-eMMC-flasher-debian-7.X-201Y-MM-DD \
    --dtb beaglebone --enable-systemd --bbb-flasher \
    --bbb-old-bootloader-in-emmc

    xz -z -8 -v BBB-eMMC-flasher-debian-7.X-201Y-MM-DD-4gb.img

2GB, microSD:

    sudo ./setup_sdcard.sh --img-2gb bone-debian-7.X-201Y-MM-DD --dtb beaglebone \
    --enable-systemd --bbb-old-bootloader-in-emmc

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
