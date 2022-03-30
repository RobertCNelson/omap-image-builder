Generate: Base Ubuntu 18.04 Image:

    git clone https://github.com/RobertCNelson/omap-image-builder
    cd ./omap-image-builder
    ./RootStock-NG.sh -c rcn-ee.net-console-ubuntu-bionic-armhf

Finalize: BeagleBone Black specific version:

    sudo ./setup_sdcard.sh --img-4gb bone-example --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru
