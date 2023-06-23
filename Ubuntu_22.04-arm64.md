Generate: Base Ubuntu 22.04 Image:

    git clone https://github.com/RobertCNelson/omap-image-builder
    cd ./omap-image-builder
    ./RootStock-NG.sh -c bb.org-ubuntu-2204-minimal-v5.10-ti-arm64-k3-j721e

Archive will be under "./deploy/"

Finalize: BeagleBone AI-64 specific version:

    sudo ./setup_sdcard.sh --img-4gb bone-example --dtb bbai64

