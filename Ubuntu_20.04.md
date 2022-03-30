Generate: Base Ubuntu 20.04 Image:

    git clone https://github.com/RobertCNelson/omap-image-builder
    cd ./omap-image-builder
    ./RootStock-NG.sh -c rcn-ee.net-console-ubuntu-focal-v5.10-ti-armhf

Archive will be under "./deploy/"

Finalize: BeagleBone Black specific version:

    sudo ./setup_sdcard.sh --img-4gb bone-example --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru --enable-bypass-bootup-scripts

Finalize: BeagleBoard-x15 specific version:

    sudo ./setup_sdcard.sh --img-4gb am57xx-example --dtb am57xx-beagle-x15 --distro-bootloader --enable-uboot-cape-overlays --enable-bypass-bootup-scripts
