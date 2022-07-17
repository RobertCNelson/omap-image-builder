Generate: Base Debian 9.13 Image:
 
 // bela image

    git clone https://github.com/RobertCNelson/omap-image-builder
    cd ./omap-image-builder
    ./RootStock-NG.sh -c bela.io-debian-stretch-armhf-v4.14-ti-xenomai
    
    
 //bela-beagle image

    git clone https://github.com/RobertCNelson/omap-image-builder
    cd ./omap-image-builder
    ./RootStock-NG.sh -c beagle-bela-stretch-bela-v4.14-ti-xenomai
        
    
    

Archive will be under "./deploy/"

Finalize: Bela-BeagleBone Black specific version:

    sudo ./setup_sdcard.sh --img-4gb bela-stretch --dtb beaglebone --distro-bootloader --enable-cape-universal --enable-uboot-disable-pru


