18.04 is now EOL

Generate: Base Ubuntu 18.04 Image:

    git clone https://github.com/RobertCNelson/omap-image-builder
    cd ./omap-image-builder
    ./RootStock-NG.sh -l rcn-ee.net-console-ubuntu-bionic-armhf

Archive will be under "./deploy/"

Finalize: BeagleBone Black specific version:

    sudo ./setup_sdcard.sh --img-4gb bone-example --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru

Finalize: BeagleBoard-x15 specific version:

    sudo ./setup_sdcard.sh --img-4gb am57xx-example --dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts
