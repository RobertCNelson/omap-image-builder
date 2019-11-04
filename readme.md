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

      A5: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 41 35 |.U3.A335BNLT00A5|]
     A5A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 41 |.U3.A335BNLT0A5A|]
     A5B: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 42 |.U3.A335BNLT0A5B|]
     A5C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 41 35 43 |.U3.A335BNLT0A5C|]
      A6: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 41 36 |.U3.A335BNLT00A6|]
       C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 30 43 |.U3.A335BNLT000C|]
       C: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 30 30 43 30 |.U3.A335BNLT00C0|]

BeagleBoard.org BeagleBone Blue:

      A2: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 42 4c 41 30 |.U3.A335BNLTBLA2|]

BeagleBoard.org BeagleBone Black Wireless:

      A5: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 42 57 41 35 |.U3.A335BNLTBWA5|]

BeagleBoard.org PocketBeagle:

      A2: [aa 55 33 ee 41 33 33 35  50 42 47 4c 30 30 41 32 |.U3.A335PBGL00A2|]

SeeedStudio BeagleBone Green:

      1A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 1a 00 00 00 |.U3.A335BNLT....|]
       ?: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 42 42 47 31 |.U3.A335BNLTBBG1|]

SeeedStudio BeagleBone Green Wireless:

     W1A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 47 57 31 41 |.U3.A335BNLTGW1A|]

SeeedStudio BeagleBone Green Gateway:

    GG1A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 47 57 31 41 |.U3.A335BNLTGG1A|]

Arrow BeagleBone Black Industrial:

      A0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 41 49 41 30 |.U3.A335BNLTAIA0|]

Element14 BeagleBone Black Industrial:

      A0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 45 49 41 30 |.U3.A335BNLTEIA0|]

SanCloud BeagleBone Enhanced:

       A: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 53 45 30 41 |.U3.A335BNLTSE0A|]

MENTOREL BeagleBone uSomIQ:

       6: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 4d 45 30 36 |.U3.A335BNLTME06|]
       
Neuromeka BeagleBone Air:

      A0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 4e 41 44 30 |.U3.A335BNLTNAD0|]

Embest replica?:

          [aa 55 33 ee 41 33 33 35  42 4e 4c 54 74 0a 75 65 |.U3.A335BNLTt.ue|]

GHI OSD3358 Dev Board:

     0.1: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 47 48 30 31 |.U3.A335BNLTGH01|]

PocketBone:

       0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 42 50 30 30 |.U3.A335BNLTBP00|]

Octavo Systems OSD3358-SM-RED:

       0: [aa 55 33 ee 41 33 33 35  42 4e 4c 54 4F 53 30 30 |.U3.A335BNLTOS00|]

BeagleLogic Standalone:

       A: [aa 55 33 ee 41 33 33 35  42 4c 47 43 30 30 30 41 |.U3.A335BLGC000A|]

Scripts to support customized image generation for many arm systems

BeagleBoard branch:
------------

    git clone https://github.com/beagleboard/image-builder.git

Release Process:

    bb.org-v201Y.MM.DD
    git tag -a bb.org-v201Y.MM.DD -m 'bb.org-v201Y.MM.DD'
    git push origin --tags

Master branch:
------------

    git clone https://github.com/RobertCNelson/omap-image-builder

eewiki.net: Debian Stable (armel) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_debian_stretch_armel

eewiki.net: Debian Stable (armhf) minfs:

    ./RootStock-NG.sh -c eewiki_minfs_debian_stretch_armhf

elinux.org: Debian Images:

    ./RootStock-NG.sh -c rcn-ee_console_debian_stretch_armhf
    ./RootStock-NG.sh -c rcn-ee_console_debian_buster_armhf
    http://elinux.org/BeagleBoardDebian#Demo_Image

elinux.org: Ubuntu Images:

    ./RootStock-NG.sh -c rcn-ee_console_ubuntu_bionic_armhf
    http://elinux.org/BeagleBoardUbuntu#Demo_Image

Release Process:

    vYEAR.MONTH
    git tag -a v201y.mm -m 'v201y.mm'
    git push origin --tags

MachineKit:
------------

    ./RootStock-NG.sh -c machinekit-debian-stretch
    http://elinux.org/Beagleboard:BeagleBoneBlack_Debian#BBW.2FBBB_.28All_Revs.29_Machinekit


# Building on Ubuntu for ARM

```
sudo apt update
sudo apt install -y binutils:armhf cpp:armhf g++:armhf make:armhf m4 dosfstools git kpartx wget parted
```

```
dpkg --list

Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                               Version                            Architecture Description
+++-==================================-==================================-============-===============================================================================
ii  accountsservice                    0.6.45-1ubuntu1                    arm64        query and manipulate user account information
ii  acl                                2.2.52-3build1                     arm64        Access control list utilities
ii  acpid                              1:2.0.28-1ubuntu1                  arm64        Advanced Configuration and Power Interface event daemon
ii  adduser                            3.116ubuntu1                       all          add and remove users and groups
ii  adwaita-icon-theme                 3.28.0-1ubuntu1                    all          default icon theme of GNOME (small subset)
ii  apparmor                           2.12-4ubuntu5.1                    arm64        user-space parser utility for AppArmor
ii  apport                             2.20.9-0ubuntu7.8                  all          automatically generate crash reports for debugging
ii  apport-symptoms                    0.20                               all          symptom scripts for apport
ii  apt                                1.6.12                             arm64        commandline package manager
ii  apt-utils                          1.6.12                             arm64        package management related utility programs
ii  at                                 3.1.20-3.1ubuntu2                  arm64        Delayed job execution and batch processing
ii  at-spi2-core                       2.28.0-1                           arm64        Assistive Technology Service Provider Interface (dbus core)
ii  base-files                         10.1ubuntu2.7                      arm64        Debian base system miscellaneous files
ii  base-passwd                        3.5.44                             arm64        Debian base system master password and group files
ii  bash                               4.4.18-2ubuntu1.2                  arm64        GNU Bourne Again SHell
ii  bash-completion                    1:2.8-1ubuntu1                     all          programmable completion for the bash shell
ii  bc                                 1.07.1-2                           arm64        GNU bc arbitrary precision calculator language
ii  bcache-tools                       1.0.8-2build1                      arm64        bcache userspace tools
ii  bind9-host                         1:9.11.3+dfsg-1ubuntu1.9           arm64        DNS lookup utility (deprecated)
ii  binutils:armhf                     2.30-21ubuntu1~18.04.2             armhf        GNU assembler, linker and binary utilities
ii  binutils-aarch64-linux-gnu         2.30-21ubuntu1~18.04.2             arm64        GNU binary utilities, for aarch64-linux-gnu target
ii  binutils-arm-linux-gnueabihf:armhf 2.30-21ubuntu1~18.04.2             armhf        GNU binary utilities, for arm-linux-gnueabihf target
ii  binutils-common:arm64              2.30-21ubuntu1~18.04.2             arm64        Common files for the GNU assembler, linker and binary utilities
ii  binutils-common:armhf              2.30-21ubuntu1~18.04.2             armhf        Common files for the GNU assembler, linker and binary utilities
ii  bsdmainutils                       11.1.2ubuntu1                      arm64        collection of more utilities from FreeBSD
ii  bsdutils                           1:2.31.1-0.4ubuntu3.4              arm64        basic utilities from 4.4BSD-Lite
ii  btrfs-progs                        4.15.1-1build1                     arm64        Checksumming Copy on Write Filesystem utilities
ii  btrfs-tools                        4.15.1-1build1                     arm64        transitional dummy package
ii  buildbot                           1.1.1-3ubuntu5                     all          transitional package for python3-buildbot
ii  busybox-initramfs                  1:1.27.2-2ubuntu3.2                arm64        Standalone shell setup for initramfs
ii  busybox-static                     1:1.27.2-2ubuntu3.2                arm64        Standalone rescue shell with tons of builtin utilities
ii  byobu                              5.125-0ubuntu1                     all          text window manager, shell multiplexer, integrated DevOps environment
ii  bzip2                              1.0.6-8.1ubuntu0.2                 arm64        high-quality block-sorting file compressor - utilities
ii  ca-certificates                    20180409                           all          Common CA certificates
ii  ca-certificates-java               20180516ubuntu1~18.04.1            all          Common CA certificates (JKS keystore)
ii  certbot                            0.31.0-1+ubuntu18.04.1+certbot+1   all          automatically configure HTTPS using Let's Encrypt
ii  cloud-guest-utils                  0.30-0ubuntu5                      all          cloud guest utilities
ii  cloud-init                         19.2-36-g059d049c-0ubuntu2~18.04.1 all          Init scripts for cloud instances
ii  cloud-initramfs-copymods           0.40ubuntu1.1                      all          copy initramfs modules into root filesystem for later use
ii  cloud-initramfs-dyn-netconf        0.40ubuntu1.1                      all          write a network interface file in /run for BOOTIF
ii  command-not-found                  18.04.5                            all          Suggest installation of packages in interactive bash sessions
ii  command-not-found-data             18.04.5                            arm64        Set of data files for command-not-found.
ii  console-setup                      1.178ubuntu2.9                     all          console font and keymap setup program
ii  console-setup-linux                1.178ubuntu2.9                     all          Linux specific part of console-setup
ii  coreutils                          8.28-1ubuntu1                      arm64        GNU core utilities
ii  cpio                               2.12+dfsg-6                        arm64        GNU cpio -- a program to manage archives of files
ii  cpp:armhf                          4:7.4.0-1ubuntu2.3                 armhf        GNU C preprocessor (cpp)
ii  cpp-7:armhf                        7.4.0-1ubuntu1~18.04.1             armhf        GNU C preprocessor
ii  cron                               3.0pl1-128.1ubuntu1                arm64        process scheduling daemon
ii  cryptsetup                         2:2.0.2-1ubuntu1.1                 arm64        disk encryption support - startup scripts
ii  cryptsetup-bin                     2:2.0.2-1ubuntu1.1                 arm64        disk encryption support - command line tools
ii  curl                               7.58.0-2ubuntu3.8                  arm64        command line tool for transferring data with URL syntax
ii  cython3                            0.26.1-0.4                         arm64        C-Extensions for Python 3
ii  dash                               0.5.8-2.10                         arm64        POSIX-compliant shell
ii  dbus                               1.12.2-1ubuntu1.1                  arm64        simple interprocess messaging system (daemon and utilities)
ii  debconf                            1.5.66ubuntu1                      all          Debian configuration management system
ii  debconf-i18n                       1.5.66ubuntu1                      all          full internationalization support for debconf
ii  debianutils                        4.8.4                              arm64        Miscellaneous utilities specific to Debian
ii  debootstrap                        1.0.115                            all          Bootstrap a basic Debian system
ii  default-jre                        2:1.11-68ubuntu1~18.04.1           arm64        Standard Java or Java compatible Runtime
ii  default-jre-headless               2:1.11-68ubuntu1~18.04.1           arm64        Standard Java or Java compatible Runtime (headless)
ii  device-tree-compiler               1.4.5-3                            arm64        Device Tree Compiler for Flat Device Trees
ii  devio                              1.2-1.2                            arm64        correctly read (or write) a region of a block device
ii  dh-python                          3.20180325ubuntu2                  all          Debian helper tools for packaging Python libraries and applications
ii  diffutils                          1:3.6-1                            arm64        File comparison utilities
ii  dirmngr                            2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - network certificate management service
ii  distro-info-data                   0.37ubuntu0.6                      all          information about the distributions' releases (data files)
ii  dmeventd                           2:1.02.145-4.1ubuntu3.18.04.1      arm64        Linux Kernel Device Mapper event daemon
ii  dmidecode                          3.1-1                              arm64        SMBIOS/DMI table decoder
ii  dmsetup                            2:1.02.145-4.1ubuntu3.18.04.1      arm64        Linux Kernel Device Mapper userspace library
ii  dns-root-data                      2018013001                         all          DNS root data including root zone and DNSSEC key
ii  dnsmasq-base                       2.79-1                             arm64        Small caching DNS proxy and DHCP/TFTP server
ii  dnsutils                           1:9.11.3+dfsg-1ubuntu1.9           arm64        Clients provided with BIND
ii  dosfstools                         4.1-1                              arm64        utilities for making and checking MS-DOS FAT filesystems
ii  dpkg                               1.19.0.5ubuntu2.3                  arm64        Debian package management system
rc  dpkg-dev                           1.19.0.5ubuntu2.3                  all          Debian package development tools
ii  e2fsprogs                          1.44.1-1ubuntu1.2                  arm64        ext2/ext3/ext4 file system utilities
ii  eatmydata                          105-6                              all          Library and utilities designed to disable fsync and friends
ii  ebtables                           2.0.10.4-3.5ubuntu2.18.04.3        arm64        Ethernet bridge frame table administration
ii  ed                                 1.10-2.1                           arm64        classic UNIX line editor
ii  efibootmgr                         15-1                               arm64        Interact with the EFI Boot Manager
ii  eject                              2.1.5+deb1+cvs20081104-13.2        arm64        ejects CDs and operates CD-Changers under Linux
ii  ethtool                            1:4.15-0ubuntu1                    arm64        display or change Ethernet device settings
ii  fakeroot                           1.22-2ubuntu1                      arm64        tool for simulating superuser privileges
ii  fdisk                              2.31.1-0.4ubuntu3.4                arm64        collection of partitioning utilities
ii  file                               1:5.32-2ubuntu0.3                  arm64        Recognize the type of data in a file using "magic" numbers
ii  findutils                          4.6.0+git+20170828-2               arm64        utilities for finding files--find, xargs
ii  flash-kernel                       3.90ubuntu3.18.04.2                arm64        utility to make certain embedded devices bootable
ii  fontconfig                         2.12.6-0ubuntu2                    arm64        generic font configuration library - support binaries
ii  fontconfig-config                  2.12.6-0ubuntu2                    all          generic font configuration library - configuration
ii  fonts-dejavu-core                  2.37-1                             all          Vera font family derivate with additional characters
ii  fonts-dejavu-extra                 2.37-1                             all          Vera font family derivate with additional characters (extra variants)
ii  fonts-ubuntu-console               0.83-2                             all          console version of the Ubuntu Mono font
ii  friendly-recovery                  0.2.38ubuntu1.1                    all          Make recovery boot mode more user-friendly
ii  ftp                                0.17-34                            arm64        classical file transfer client
ii  fuse                               2.9.7-1ubuntu1                     arm64        Filesystem in Userspace
ii  g++:armhf                          4:7.4.0-1ubuntu2.3                 armhf        GNU C++ compiler
ii  g++-7:armhf                        7.4.0-1ubuntu1~18.04.1             armhf        GNU C++ compiler
ii  gawk                               1:4.1.4+dfsg-1build1               arm64        GNU awk, a pattern scanning and processing language
ii  gcc:armhf                          4:7.4.0-1ubuntu2.3                 armhf        GNU C compiler
ii  gcc-7:armhf                        7.4.0-1ubuntu1~18.04.1             armhf        GNU C compiler
ii  gcc-7-base:armhf                   7.4.0-1ubuntu1~18.04.1             armhf        GCC, the GNU Compiler Collection (base package)
ii  gcc-8-base:arm64                   8.3.0-6ubuntu1~18.04.1             arm64        GCC, the GNU Compiler Collection (base package)
ii  gcc-8-base:armhf                   8.3.0-6ubuntu1~18.04.1             armhf        GCC, the GNU Compiler Collection (base package)
ii  gdisk                              1.0.3-1                            arm64        GPT fdisk text-mode partitioning tool
ii  geoip-database                     20180315-1                         all          IP lookup command line tools that use the GeoIP library (country database)
ii  gettext-base                       0.19.8.1-6ubuntu0.3                arm64        GNU Internationalization utilities for the base system
ii  gir1.2-glib-2.0:arm64              1.56.1-1                           arm64        Introspection data for GLib, GObject, Gio and GModule
ii  git                                1:2.17.1-1ubuntu0.4                arm64        fast, scalable, distributed revision control system
ii  git-man                            1:2.17.1-1ubuntu0.4                all          fast, scalable, distributed revision control system (manual pages)
ii  gnupg                              2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - a free PGP replacement
ii  gnupg-l10n                         2.2.4-1ubuntu1.2                   all          GNU privacy guard - localization files
ii  gnupg-utils                        2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - utility programs
ii  gpg                                2.2.4-1ubuntu1.2                   arm64        GNU Privacy Guard -- minimalist public key operations
ii  gpg-agent                          2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - cryptographic agent
ii  gpg-wks-client                     2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - Web Key Service client
ii  gpg-wks-server                     2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - Web Key Service server
ii  gpgconf                            2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - core configuration utilities
ii  gpgsm                              2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - S/MIME version
ii  gpgv                               2.2.4-1ubuntu1.2                   arm64        GNU privacy guard - signature verification tool
ii  grep                               3.1-2build1                        arm64        GNU grep, egrep and fgrep
ii  groff-base                         1.22.3-10                          arm64        GNU troff text-formatting system (base system components)
ii  grub-common                        2.02-2ubuntu8.13                   arm64        GRand Unified Bootloader (common files)
ii  grub-efi-arm64                     2.02-2ubuntu8.13                   arm64        GRand Unified Bootloader, version 2 (ARM64 UEFI version)
ii  grub-efi-arm64-bin                 2.02-2ubuntu8.13                   arm64        GRand Unified Bootloader, version 2 (ARM64 UEFI binaries)
ii  grub2-common                       2.02-2ubuntu8.13                   arm64        GRand Unified Bootloader (common files for version 2)
ii  gtk-update-icon-cache              3.22.30-1ubuntu4                   arm64        icon theme caching utility
ii  gzip                               1.6-5ubuntu1                       arm64        GNU compression utilities
ii  hdparm                             9.54+ds-1                          arm64        tune hard disk parameters for high performance
ii  hibagent                           1.0.1-0ubuntu1                     all          Agent that triggers hibernation on EC2 instances
ii  hicolor-icon-theme                 0.17-2                             all          default fallback theme for FreeDesktop.org icon themes
ii  hostname                           3.20                               arm64        utility to set/show the host name or domain name
ii  htop                               2.1.0-3                            arm64        interactive processes viewer
ii  humanity-icon-theme                0.6.15                             all          Humanity Icon theme
ii  info                               6.5.0.dfsg.1-2                     arm64        Standalone GNU Info documentation browser
ii  init                               1.51                               arm64        metapackage ensuring an init system is installed
ii  init-system-helpers                1.51                               all          helper tools for all init systems
ii  initramfs-tools                    0.130ubuntu3.8                     all          generic modular initramfs generator (automation)
ii  initramfs-tools-bin                0.130ubuntu3.8                     arm64        binaries used by initramfs-tools
ii  initramfs-tools-core               0.130ubuntu3.8                     all          generic modular initramfs generator (core tools)
ii  install-info                       6.5.0.dfsg.1-2                     arm64        Manage installed documentation in info format
ii  iproute2                           4.15.0-2ubuntu1                    arm64        networking and traffic control tools
ii  iptables                           1.6.1-2ubuntu2                     arm64        administration tools for packet filtering and NAT
ii  iputils-ping                       3:20161105-1ubuntu3                arm64        Tools to test the reachability of network hosts
ii  iputils-tracepath                  3:20161105-1ubuntu3                arm64        Tools to trace the network path to a remote host
ii  irqbalance                         1.3.0-0.1ubuntu0.18.04.1           arm64        Daemon to balance interrupts for SMP systems
ii  isc-dhcp-client                    4.3.5-3ubuntu7.1                   arm64        DHCP client for automatically obtaining an IP address
ii  isc-dhcp-common                    4.3.5-3ubuntu7.1                   arm64        common manpages relevant to all of the isc-dhcp packages
ii  iso-codes                          3.79-1                             all          ISO language, territory, currency, script codes and their translations
ii  java-common                        0.68ubuntu1~18.04.1                all          Base package for Java runtimes
ii  kbd                                2.0.4-2ubuntu1                     arm64        Linux console font and keytable utilities
ii  keyboard-configuration             1.178ubuntu2.9                     all          system-wide keyboard preferences
ii  klibc-utils                        2.0.4-9ubuntu2                     arm64        small utilities built with klibc for early boot
ii  kmod                               24-1ubuntu3.2                      arm64        tools for managing Linux kernel modules
ii  kpartx                             0.7.4-2ubuntu3                     arm64        create device mappings for partitions
ii  krb5-locales                       1.16-2ubuntu0.1                    all          internationalization support for MIT Kerberos
ii  landscape-common                   18.01-0ubuntu3.4                   arm64        Landscape administration system client - Common files
ii  language-selector-common           0.188.3                            all          Language selector for Ubuntu
ii  less                               487-0.1                            arm64        pager program similar to more
ii  libaccountsservice0:arm64          0.6.45-1ubuntu1                    arm64        query and manipulate user account information - shared libraries
ii  libacl1:arm64                      2.2.52-3build1                     arm64        Access control list shared library
ii  libaio1:arm64                      0.3.110-5ubuntu0.1                 arm64        Linux kernel AIO access library - shared library
ii  libalgorithm-diff-perl             1.19.03-1                          all          module to find differences between files
ii  libalgorithm-diff-xs-perl          0.04-5                             arm64        module to find differences between files (XS accelerated)
ii  libalgorithm-merge-perl            0.08-3                             all          Perl module for three-way merge of textual data
ii  libapparmor1:arm64                 2.12-4ubuntu5.1                    arm64        changehat AppArmor library
ii  libapt-inst2.0:arm64               1.6.12                             arm64        deb package format runtime library
ii  libapt-pkg5.0:arm64                1.6.12                             arm64        package management runtime library
ii  libargon2-0:arm64                  0~20161029-1.1                     arm64        memory-hard hashing function - runtime library
ii  libasan4:armhf                     7.4.0-1ubuntu1~18.04.1             armhf        AddressSanitizer -- a fast memory error detector
ii  libasn1-8-heimdal:arm64            7.5.0+dfsg-1                       arm64        Heimdal Kerberos - ASN.1 library
ii  libasound2:arm64                   1.1.3-5ubuntu0.2                   arm64        shared library for ALSA applications
ii  libasound2-data                    1.1.3-5ubuntu0.2                   all          Configuration files and profiles for ALSA drivers
ii  libassuan0:arm64                   2.5.1-2                            arm64        IPC library for the GnuPG components
ii  libasyncns0:arm64                  0.8-6                              arm64        Asynchronous name service query library
ii  libatk-bridge2.0-0:arm64           2.26.2-1                           arm64        AT-SPI 2 toolkit bridge - shared library
ii  libatk-wrapper-java                0.33.3-20ubuntu0.1                 all          ATK implementation for Java using JNI
ii  libatk-wrapper-java-jni:arm64      0.33.3-20ubuntu0.1                 arm64        ATK implementation for Java using JNI (JNI bindings)
ii  libatk1.0-0:arm64                  2.28.1-1                           arm64        ATK accessibility toolkit
ii  libatk1.0-data                     2.28.1-1                           all          Common files for the ATK accessibility toolkit
ii  libatm1:arm64                      1:2.5.1-2build1                    arm64        shared library for ATM (Asynchronous Transfer Mode)
ii  libatomic1:arm64                   8.3.0-6ubuntu1~18.04.1             arm64        support library providing __atomic built-in functions
ii  libatomic1:armhf                   8.3.0-6ubuntu1~18.04.1             armhf        support library providing __atomic built-in functions
ii  libatspi2.0-0:arm64                2.28.0-1                           arm64        Assistive Technology Service Provider Interface - shared library
ii  libattr1:arm64                     1:2.4.47-2build1                   arm64        Extended attribute shared library
ii  libaudit-common                    1:2.8.2-1ubuntu1                   all          Dynamic library for security auditing - common files
ii  libaudit1:arm64                    1:2.8.2-1ubuntu1                   arm64        Dynamic library for security auditing
ii  libavahi-client3:arm64             0.7-3.1ubuntu1.2                   arm64        Avahi client library
ii  libavahi-common-data:arm64         0.7-3.1ubuntu1.2                   arm64        Avahi common data files
ii  libavahi-common3:arm64             0.7-3.1ubuntu1.2                   arm64        Avahi common library
ii  libbind9-160:arm64                 1:9.11.3+dfsg-1ubuntu1.9           arm64        BIND9 Shared Library used by BIND
ii  libbinutils:arm64                  2.30-21ubuntu1~18.04.2             arm64        GNU binary utilities (private shared library)
ii  libbinutils:armhf                  2.30-21ubuntu1~18.04.2             armhf        GNU binary utilities (private shared library)
ii  libblkid1:arm64                    2.31.1-0.4ubuntu3.4                arm64        block device ID library
ii  libbsd0:arm64                      0.8.7-1                            arm64        utility functions from BSD systems - shared library
ii  libbz2-1.0:arm64                   1.0.6-8.1ubuntu0.2                 arm64        high-quality block-sorting file compressor library - runtime
ii  libc-bin                           2.27-3ubuntu1                      arm64        GNU C Library: Binaries
ii  libc-dev-bin                       2.27-3ubuntu1                      arm64        GNU C Library: Development binaries
ii  libc6:arm64                        2.27-3ubuntu1                      arm64        GNU C Library: Shared libraries
ii  libc6:armhf                        2.27-3ubuntu1                      armhf        GNU C Library: Shared libraries
ii  libc6-dev:arm64                    2.27-3ubuntu1                      arm64        GNU C Library: Development Libraries and Header Files
ii  libc6-dev:armhf                    2.27-3ubuntu1                      armhf        GNU C Library: Development Libraries and Header Files
ii  libcairo2:arm64                    1.15.10-2ubuntu0.1                 arm64        Cairo 2D vector graphics library
ii  libcap-ng0:arm64                   0.7.7-3.1                          arm64        An alternate POSIX capabilities library
ii  libcap2:arm64                      1:2.25-1.2                         arm64        POSIX 1003.1e capabilities (library)
ii  libcap2-bin                        1:2.25-1.2                         arm64        POSIX 1003.1e capabilities (utilities)
ii  libcc1-0:armhf                     8.3.0-6ubuntu1~18.04.1             armhf        GCC cc1 plugin for GDB
ii  libcgi-fast-perl                   1:2.13-1                           all          CGI subclass for work with FCGI
ii  libcgi-pm-perl                     4.38-1                             all          module for Common Gateway Interface applications
ii  libcilkrts5:armhf                  7.4.0-1ubuntu1~18.04.1             armhf        Intel Cilk Plus language extensions (runtime)
ii  libcom-err2:arm64                  1.44.1-1ubuntu1.2                  arm64        common error description library
ii  libcroco3:arm64                    0.6.12-2                           arm64        Cascading Style Sheet (CSS) parsing and manipulation toolkit
ii  libcryptsetup12:arm64              2:2.0.2-1ubuntu1.1                 arm64        disk encryption support - shared library
ii  libcups2:arm64                     2.2.7-1ubuntu2.7                   arm64        Common UNIX Printing System(tm) - Core library
ii  libcurl3-gnutls:arm64              7.58.0-2ubuntu3.8                  arm64        easy-to-use client-side URL transfer library (GnuTLS flavour)
ii  libcurl4:arm64                     7.58.0-2ubuntu3.8                  arm64        easy-to-use client-side URL transfer library (OpenSSL flavour)
ii  libdatrie1:arm64                   0.2.10-7                           arm64        Double-array trie library
ii  libdb5.3:arm64                     5.3.28-13.1ubuntu1.1               arm64        Berkeley v5.3 Database Libraries [runtime]
ii  libdbus-1-3:arm64                  1.12.2-1ubuntu1.1                  arm64        simple interprocess messaging system (library)
ii  libdebconfclient0:arm64            0.213ubuntu1                       arm64        Debian Configuration Management System (C-implementation library)
ii  libdevmapper-event1.02.1:arm64     2:1.02.145-4.1ubuntu3.18.04.1      arm64        Linux Kernel Device Mapper event support library
ii  libdevmapper1.02.1:arm64           2:1.02.145-4.1ubuntu3.18.04.1      arm64        Linux Kernel Device Mapper userspace library
ii  libdns-export1100                  1:9.11.3+dfsg-1ubuntu1.9           arm64        Exported DNS Shared Library
ii  libdns1100:arm64                   1:9.11.3+dfsg-1ubuntu1.9           arm64        DNS Shared Library used by BIND
ii  libdpkg-perl                       1.19.0.5ubuntu2.3                  all          Dpkg perl modules
ii  libdrm-amdgpu1:arm64               2.4.97-1ubuntu1~18.04.1            arm64        Userspace interface to amdgpu-specific kernel DRM services -- runtime
ii  libdrm-common                      2.4.97-1ubuntu1~18.04.1            all          Userspace interface to kernel DRM services -- common files
ii  libdrm-etnaviv1:arm64              2.4.97-1ubuntu1~18.04.1            arm64        Userspace interface to etnaviv-specific kernel DRM services -- runtime
ii  libdrm-nouveau2:arm64              2.4.97-1ubuntu1~18.04.1            arm64        Userspace interface to nouveau-specific kernel DRM services -- runtime
ii  libdrm-radeon1:arm64               2.4.97-1ubuntu1~18.04.1            arm64        Userspace interface to radeon-specific kernel DRM services -- runtime
ii  libdrm2:arm64                      2.4.97-1ubuntu1~18.04.1            arm64        Userspace interface to kernel DRM services -- runtime
ii  libeatmydata1:arm64                105-6                              arm64        Library and utilities to disable fsync and friends - shared library
ii  libedit2:arm64                     3.1-20170329-1                     arm64        BSD editline and history libraries
ii  libefiboot1:arm64                  34-1                               arm64        Library to manage UEFI variables
ii  libefivar1:arm64                   34-1                               arm64        Library to manage UEFI variables
ii  libelf1:arm64                      0.170-0.4ubuntu0.1                 arm64        library to read and write ELF files
ii  libencode-locale-perl              1.05-1                             all          utility to determine the locale encoding
ii  liberror-perl                      0.17025-1                          all          Perl module for error/exception handling in an OO-ish way
ii  libestr0:arm64                     0.1.10-2.1                         arm64        Helper functions for handling strings (lib)
ii  libevent-2.1-6:arm64               2.1.8-stable-4build1               arm64        Asynchronous event notification library
ii  libevent-core-2.1-6:arm64          2.1.8-stable-4build1               arm64        Asynchronous event notification library (core)
ii  libexpat1:arm64                    2.2.5-3ubuntu0.2                   arm64        XML parsing C library - runtime library
ii  libexpat1-dev:arm64                2.2.5-3ubuntu0.2                   arm64        XML parsing C library - development kit
ii  libext2fs2:arm64                   1.44.1-1ubuntu1.2                  arm64        ext2/ext3/ext4 file system libraries
ii  libfakeroot:arm64                  1.22-2ubuntu1                      arm64        tool for simulating superuser privileges - shared libraries
ii  libfastjson4:arm64                 0.99.8-2                           arm64        fast json library for C
ii  libfcgi-perl                       0.78-2build1                       arm64        helper module for FastCGI
ii  libfdisk1:arm64                    2.31.1-0.4ubuntu3.4                arm64        fdisk partitioning library
ii  libffi6:arm64                      3.2.1-8                            arm64        Foreign Function Interface library runtime
ii  libfile-fcntllock-perl             0.22-3build2                       arm64        Perl module for file locking with fcntl(2)
ii  libflac8:arm64                     1.3.2-1                            arm64        Free Lossless Audio Codec - runtime C library
ii  libfontconfig1:arm64               2.12.6-0ubuntu2                    arm64        generic font configuration library - runtime
ii  libfontenc1:arm64                  1:1.1.3-1                          arm64        X11 font encoding library
ii  libfreetype6:arm64                 2.8.1-2ubuntu2                     arm64        FreeType 2 font engine, shared library files
ii  libfribidi0:arm64                  0.19.7-2                           arm64        Free Implementation of the Unicode BiDi algorithm
ii  libfuse2:arm64                     2.9.7-1ubuntu1                     arm64        Filesystem in Userspace (library)
ii  libgail-common:arm64               2.24.32-1ubuntu1                   arm64        GNOME Accessibility Implementation Library -- common modules
ii  libgail18:arm64                    2.24.32-1ubuntu1                   arm64        GNOME Accessibility Implementation Library -- shared libraries
ii  libgcc-7-dev:armhf                 7.4.0-1ubuntu1~18.04.1             armhf        GCC support library (development files)
ii  libgcc1:arm64                      1:8.3.0-6ubuntu1~18.04.1           arm64        GCC support library
ii  libgcc1:armhf                      1:8.3.0-6ubuntu1~18.04.1           armhf        GCC support library
ii  libgcrypt20:arm64                  1.8.1-4ubuntu1.1                   arm64        LGPL Crypto library - runtime library
ii  libgd3:arm64                       2.2.5-4ubuntu0.3                   arm64        GD Graphics Library
ii  libgdbm-compat4:arm64              1.14.1-6                           arm64        GNU dbm database routines (legacy support runtime version) 
ii  libgdbm5:arm64                     1.14.1-6                           arm64        GNU dbm database routines (runtime version) 
ii  libgdk-pixbuf2.0-0:arm64           2.36.11-2                          arm64        GDK Pixbuf library
ii  libgdk-pixbuf2.0-bin               2.36.11-2                          arm64        GDK Pixbuf library (thumbnailer)
ii  libgdk-pixbuf2.0-common            2.36.11-2                          all          GDK Pixbuf library - data files
ii  libgeoip1:arm64                    1.6.12-1                           arm64        non-DNS IP-to-country resolver library
ii  libgif7:arm64                      5.1.4-2ubuntu0.1                   arm64        library for GIF images (library)
ii  libgirepository-1.0-1:arm64        1.56.1-1                           arm64        Library for handling GObject introspection data (runtime library)
ii  libgl1:arm64                       1.0.0-2ubuntu2.3                   arm64        Vendor neutral GL dispatch library -- legacy GL support
ii  libgl1-mesa-dri:arm64              19.0.8-0ubuntu0~18.04.3            arm64        free implementation of the OpenGL API -- DRI modules
ii  libglapi-mesa:arm64                19.0.8-0ubuntu0~18.04.3            arm64        free implementation of the GL API -- shared library
ii  libglib2.0-0:arm64                 2.56.4-0ubuntu0.18.04.4            arm64        GLib library of C routines
ii  libglib2.0-data                    2.56.4-0ubuntu0.18.04.4            all          Common files for GLib library
ii  libglvnd0:arm64                    1.0.0-2ubuntu2.3                   arm64        Vendor neutral GL dispatch library
ii  libglx-mesa0:arm64                 19.0.8-0ubuntu0~18.04.3            arm64        free implementation of the OpenGL API -- GLX vendor library
ii  libglx0:arm64                      1.0.0-2ubuntu2.3                   arm64        Vendor neutral GL dispatch library -- GLX support
ii  libgmp10:arm64                     2:6.1.2+dfsg-2                     arm64        Multiprecision arithmetic library
ii  libgmp10:armhf                     2:6.1.2+dfsg-2                     armhf        Multiprecision arithmetic library
ii  libgnutls30:arm64                  3.5.18-1ubuntu1.1                  arm64        GNU TLS library - main runtime library
ii  libgomp1:arm64                     8.3.0-6ubuntu1~18.04.1             arm64        GCC OpenMP (GOMP) support library
ii  libgomp1:armhf                     8.3.0-6ubuntu1~18.04.1             armhf        GCC OpenMP (GOMP) support library
ii  libgpg-error0:arm64                1.27-6                             arm64        library for common error values and messages in GnuPG components
ii  libgpm2:arm64                      1.20.7-5                           arm64        General Purpose Mouse - shared library
ii  libgraphite2-3:arm64               1.3.11-2                           arm64        Font rendering engine for Complex Scripts -- library
ii  libgssapi-krb5-2:arm64             1.16-2ubuntu0.1                    arm64        MIT Kerberos runtime libraries - krb5 GSS-API Mechanism
ii  libgssapi3-heimdal:arm64           7.5.0+dfsg-1                       arm64        Heimdal Kerberos - GSSAPI support library
ii  libgtk2.0-0:arm64                  2.24.32-1ubuntu1                   arm64        GTK+ graphical user interface library
ii  libgtk2.0-bin                      2.24.32-1ubuntu1                   arm64        programs for the GTK+ graphical user interface library
ii  libgtk2.0-common                   2.24.32-1ubuntu1                   all          common files for the GTK+ graphical user interface library
ii  libharfbuzz0b:arm64                1.7.2-1ubuntu1                     arm64        OpenType text shaping engine (shared library)
ii  libhcrypto4-heimdal:arm64          7.5.0+dfsg-1                       arm64        Heimdal Kerberos - crypto library
ii  libheimbase1-heimdal:arm64         7.5.0+dfsg-1                       arm64        Heimdal Kerberos - Base library
ii  libheimntlm0-heimdal:arm64         7.5.0+dfsg-1                       arm64        Heimdal Kerberos - NTLM support library
ii  libhogweed4:arm64                  3.4-1                              arm64        low level cryptographic library (public-key cryptos)
ii  libhtml-parser-perl                3.72-3build1                       arm64        collection of modules that parse HTML text documents
ii  libhtml-tagset-perl                3.20-3                             all          Data tables pertaining to HTML
ii  libhtml-template-perl              2.97-1                             all          module for using HTML templates with Perl
ii  libhttp-date-perl                  6.02-1                             all          module of date conversion routines
ii  libhttp-message-perl               6.14-1                             all          perl interface to HTTP style messages
ii  libhx509-5-heimdal:arm64           7.5.0+dfsg-1                       arm64        Heimdal Kerberos - X509 support library
ii  libice6:arm64                      2:1.0.9-2                          arm64        X11 Inter-Client Exchange library
ii  libicu60:arm64                     60.2-3ubuntu3                      arm64        International Components for Unicode
ii  libidn11:arm64                     1.33-2.1ubuntu1.2                  arm64        GNU Libidn library, implementation of IETF IDN specifications
ii  libidn2-0:arm64                    2.0.4-1.1ubuntu0.2                 arm64        Internationalized domain names (IDNA2008/TR46) library
ii  libio-html-perl                    1.001-1                            all          open an HTML file with automatic charset detection
ii  libip4tc0:arm64                    1.6.1-2ubuntu2                     arm64        netfilter libip4tc library
ii  libip6tc0:arm64                    1.6.1-2ubuntu2                     arm64        netfilter libip6tc library
ii  libiptc0:arm64                     1.6.1-2ubuntu2                     arm64        netfilter libiptc library
ii  libirs160:arm64                    1:9.11.3+dfsg-1ubuntu1.9           arm64        DNS Shared Library used by BIND
ii  libisc-export169:arm64             1:9.11.3+dfsg-1ubuntu1.9           arm64        Exported ISC Shared Library
ii  libisc169:arm64                    1:9.11.3+dfsg-1ubuntu1.9           arm64        ISC Shared Library used by BIND
ii  libisccc160:arm64                  1:9.11.3+dfsg-1ubuntu1.9           arm64        Command Channel Library used by BIND
ii  libisccfg160:arm64                 1:9.11.3+dfsg-1ubuntu1.9           arm64        Config File Handling Library used by BIND
ii  libisl19:armhf                     0.19-1                             armhf        manipulating sets and relations of integer points bounded by linear constraints
ii  libisns0:arm64                     0.97-2build1                       arm64        Internet Storage Name Service - shared libraries
ii  libitm1:arm64                      8.3.0-6ubuntu1~18.04.1             arm64        GNU Transactional Memory Library
ii  libjbig0:arm64                     2.1-3.1build1                      arm64        JBIGkit libraries
ii  libjpeg-turbo8:arm64               1.5.2-0ubuntu5.18.04.1             arm64        IJG JPEG compliant runtime library.
ii  libjpeg8:arm64                     8c-2ubuntu8                        arm64        Independent JPEG Group's JPEG runtime library (dependency package)
ii  libjson-c3:arm64                   0.12.1-1.3                         arm64        JSON manipulation library - shared library
ii  libk5crypto3:arm64                 1.16-2ubuntu0.1                    arm64        MIT Kerberos runtime libraries - Crypto Library
ii  libkeyutils1:arm64                 1.5.9-9.2ubuntu2                   arm64        Linux Key Management Utilities (library)
ii  libklibc                           2.0.4-9ubuntu2                     arm64        minimal libc subset for use with initramfs
ii  libkmod2:arm64                     24-1ubuntu3.2                      arm64        libkmod shared library
ii  libkrb5-26-heimdal:arm64           7.5.0+dfsg-1                       arm64        Heimdal Kerberos - libraries
ii  libkrb5-3:arm64                    1.16-2ubuntu0.1                    arm64        MIT Kerberos runtime libraries
ii  libkrb5support0:arm64              1.16-2ubuntu0.1                    arm64        MIT Kerberos runtime libraries - Support library
ii  libksba8:arm64                     1.3.5-2                            arm64        X.509 and CMS support library
ii  liblcms2-2:arm64                   2.9-1ubuntu0.1                     arm64        Little CMS 2 color management library
ii  libldap-2.4-2:arm64                2.4.45+dfsg-1ubuntu1.4             arm64        OpenLDAP libraries
ii  libldap-common                     2.4.45+dfsg-1ubuntu1.4             all          OpenLDAP common files for libraries
ii  libllvm8:arm64                     1:8-3~ubuntu18.04.1                arm64        Modular compiler and toolchain technologies, runtime library
ii  liblocale-gettext-perl             1.07-3build2                       arm64        module using libc functions for internationalization in Perl
ii  liblsan0:arm64                     8.3.0-6ubuntu1~18.04.1             arm64        LeakSanitizer -- a memory leak detector (runtime)
ii  liblvm2app2.2:arm64                2.02.176-4.1ubuntu3.18.04.1        arm64        LVM2 application library
ii  liblvm2cmd2.02:arm64               2.02.176-4.1ubuntu3.18.04.1        arm64        LVM2 command library
ii  liblwp-mediatypes-perl             6.02-1                             all          module to guess media type for a file or a URL
ii  liblwres160:arm64                  1:9.11.3+dfsg-1ubuntu1.9           arm64        Lightweight Resolver Library used by BIND
ii  liblxc-common                      3.0.3-0ubuntu1~18.04.1             arm64        Linux Containers userspace tools (common tools)
ii  liblxc1                            3.0.3-0ubuntu1~18.04.1             arm64        Linux Containers userspace tools (library)
ii  liblz4-1:arm64                     0.0~r131-2ubuntu3                  arm64        Fast LZ compression algorithm library - runtime
ii  liblzma5:arm64                     5.2.2-1.3                          arm64        XZ-format compression library
ii  liblzo2-2:arm64                    2.08-1.2                           arm64        data compression library
ii  libmagic-mgc                       1:5.32-2ubuntu0.3                  arm64        File type determination library using "magic" numbers (compiled magic file)
ii  libmagic1:arm64                    1:5.32-2ubuntu0.3                  arm64        Recognize the type of data in a file using "magic" numbers - library
ii  libmnl0:arm64                      1.0.4-2                            arm64        minimalistic Netlink communication library
ii  libmount1:arm64                    2.31.1-0.4ubuntu3.4                arm64        device mounting library
ii  libmpc3:armhf                      1.1.0-1                            armhf        multiple precision complex floating-point library
ii  libmpdec2:arm64                    2.4.2-1ubuntu1                     arm64        library for decimal floating point arithmetic (runtime library)
ii  libmpfr6:arm64                     4.0.1-1                            arm64        multiple precision floating-point computation
ii  libmpfr6:armhf                     4.0.1-1                            armhf        multiple precision floating-point computation
ii  libncurses5:arm64                  6.1-1ubuntu1.18.04                 arm64        shared libraries for terminal handling
ii  libncursesw5:arm64                 6.1-1ubuntu1.18.04                 arm64        shared libraries for terminal handling (wide character support)
ii  libnetfilter-conntrack3:arm64      1.0.6-2                            arm64        Netfilter netlink-conntrack library
ii  libnettle6:arm64                   3.4-1                              arm64        low level cryptographic library (symmetric and one-way cryptos)
ii  libnewt0.52:arm64                  0.52.20-1ubuntu1                   arm64        Not Erik's Windowing Toolkit - text mode windowing with slang
ii  libnfnetlink0:arm64                1.0.1-3                            arm64        Netfilter netlink library
ii  libnghttp2-14:arm64                1.30.0-1ubuntu1                    arm64        library implementing HTTP/2 protocol (shared library)
ii  libnginx-mod-http-geoip            1.14.0-0ubuntu1.6                  arm64        GeoIP HTTP module for Nginx
ii  libnginx-mod-http-image-filter     1.14.0-0ubuntu1.6                  arm64        HTTP image filter module for Nginx
ii  libnginx-mod-http-xslt-filter      1.14.0-0ubuntu1.6                  arm64        XSLT Transformation module for Nginx
ii  libnginx-mod-mail                  1.14.0-0ubuntu1.6                  arm64        Mail module for Nginx
ii  libnginx-mod-stream                1.14.0-0ubuntu1.6                  arm64        Stream module for Nginx
ii  libnih1:arm64                      1.0.3-6ubuntu2                     arm64        NIH Utility Library
ii  libnpth0:arm64                     1.5-3                              arm64        replacement for GNU Pth using system threads
ii  libnspr4:arm64                     2:4.18-1ubuntu1                    arm64        NetScape Portable Runtime Library
ii  libnss-systemd:arm64               237-3ubuntu10.31                   arm64        nss module providing dynamic user and group name resolution
ii  libnss3:arm64                      2:3.35-2ubuntu2.3                  arm64        Network Security Service libraries
ii  libntfs-3g88                       1:2017.3.23-2ubuntu0.18.04.2       arm64        read/write NTFS driver for FUSE (runtime library)
ii  libnuma1:arm64                     2.0.11-2.1ubuntu0.1                arm64        Libraries for controlling NUMA policy
ii  libogg0:arm64                      1.3.2-1                            arm64        Ogg bitstream library
ii  libp11-kit0:arm64                  0.23.9-2                           arm64        library for loading and coordinating access to PKCS#11 modules - runtime
ii  libpam-cap:arm64                   1:2.25-1.2                         arm64        POSIX 1003.1e capabilities (PAM module)
ii  libpam-modules:arm64               1.1.8-3.6ubuntu2.18.04.1           arm64        Pluggable Authentication Modules for PAM
ii  libpam-modules-bin                 1.1.8-3.6ubuntu2.18.04.1           arm64        Pluggable Authentication Modules for PAM - helper binaries
ii  libpam-runtime                     1.1.8-3.6ubuntu2.18.04.1           all          Runtime support for the PAM library
ii  libpam-systemd:arm64               237-3ubuntu10.31                   arm64        system and service manager - PAM module
ii  libpam0g:arm64                     1.1.8-3.6ubuntu2.18.04.1           arm64        Pluggable Authentication Modules library
ii  libpango-1.0-0:arm64               1.40.14-1ubuntu0.1                 arm64        Layout and rendering of internationalized text
ii  libpangocairo-1.0-0:arm64          1.40.14-1ubuntu0.1                 arm64        Layout and rendering of internationalized text
ii  libpangoft2-1.0-0:arm64            1.40.14-1ubuntu0.1                 arm64        Layout and rendering of internationalized text
ii  libparted2:arm64                   3.2-20ubuntu0.2                    arm64        disk partition manipulator - shared library
ii  libpcap0.8:arm64                   1.8.1-6ubuntu1                     arm64        system interface for user-level packet capture
ii  libpci3:arm64                      1:3.5.2-1ubuntu1.1                 arm64        Linux PCI Utilities (shared library)
ii  libpcre3:arm64                     2:8.39-9                           arm64        Old Perl 5 Compatible Regular Expression Library - runtime files
ii  libpcsclite1:arm64                 1.8.23-1                           arm64        Middleware to access a smart card using PC/SC (library)
ii  libperl5.26:arm64                  5.26.1-6ubuntu0.3                  arm64        shared Perl library
ii  libpipeline1:arm64                 1.5.0-1                            arm64        pipeline manipulation library
ii  libpixman-1-0:arm64                0.34.0-2                           arm64        pixel-manipulation library for X and cairo
ii  libplymouth4:arm64                 0.9.3-1ubuntu7.18.04.2             arm64        graphical boot animation and logger - shared libraries
ii  libpng16-16:arm64                  1.6.34-1ubuntu0.18.04.2            arm64        PNG library - runtime (version 1.6)
ii  libpolkit-agent-1-0:arm64          0.105-20ubuntu0.18.04.5            arm64        PolicyKit Authentication Agent API
ii  libpolkit-backend-1-0:arm64        0.105-20ubuntu0.18.04.5            arm64        PolicyKit backend API
ii  libpolkit-gobject-1-0:arm64        0.105-20ubuntu0.18.04.5            arm64        PolicyKit Authorization API
ii  libpopt0:arm64                     1.16-11                            arm64        lib for parsing cmdline parameters
ii  libprocps6:arm64                   2:3.3.12-3ubuntu1.2                arm64        library for accessing process information from /proc
ii  libpsl5:arm64                      0.19.1-5build1                     arm64        Library for Public Suffix List (shared libraries)
ii  libpulse0:arm64                    1:11.1-1ubuntu7.2                  arm64        PulseAudio client libraries
ii  libpython3-dev:arm64               3.6.7-1~18.04                      arm64        header files and a static library for Python (default)
ii  libpython3-stdlib:arm64            3.6.7-1~18.04                      arm64        interactive high-level object-oriented language (default python3 version)
ii  libpython3.6:arm64                 3.6.8-1~18.04.3                    arm64        Shared Python runtime library (version 3.6)
ii  libpython3.6-dev:arm64             3.6.8-1~18.04.3                    arm64        Header files and a static library for Python (v3.6)
ii  libpython3.6-minimal:arm64         3.6.8-1~18.04.3                    arm64        Minimal subset of the Python language (version 3.6)
ii  libpython3.6-stdlib:arm64          3.6.8-1~18.04.3                    arm64        Interactive high-level object-oriented language (standard library, version 3.6)
ii  libreadline5:arm64                 5.2+dfsg-3build1                   arm64        GNU readline and history libraries, run-time libraries
ii  libreadline7:arm64                 7.0-3                              arm64        GNU readline and history libraries, run-time libraries
ii  libroken18-heimdal:arm64           7.5.0+dfsg-1                       arm64        Heimdal Kerberos - roken support library
ii  librsvg2-2:arm64                   2.40.20-2                          arm64        SAX-based renderer library for SVG files (runtime)
ii  librsvg2-common:arm64              2.40.20-2                          arm64        SAX-based renderer library for SVG files (extra runtime)
ii  librtmp1:arm64                     2.4+20151223.gitfa8646d.1-1        arm64        toolkit for RTMP streams (shared library)
ii  libsasl2-2:arm64                   2.1.27~101-g0780600+dfsg-3ubuntu2  arm64        Cyrus SASL - authentication abstraction library
ii  libsasl2-modules:arm64             2.1.27~101-g0780600+dfsg-3ubuntu2  arm64        Cyrus SASL - pluggable authentication modules
ii  libsasl2-modules-db:arm64          2.1.27~101-g0780600+dfsg-3ubuntu2  arm64        Cyrus SASL - pluggable authentication modules (DB)
ii  libseccomp2:arm64                  2.4.1-0ubuntu0.18.04.2             arm64        high level interface to Linux seccomp filter
ii  libselinux1:arm64                  2.7-2build2                        arm64        SELinux runtime shared libraries
ii  libsemanage-common                 2.7-2build2                        all          Common files for SELinux policy management libraries
ii  libsemanage1:arm64                 2.7-2build2                        arm64        SELinux policy management library
ii  libsensors4:arm64                  1:3.4.0-4                          arm64        library to read temperature/voltage/fan sensors
ii  libsepol1:arm64                    2.7-1                              arm64        SELinux library for manipulating binary security policies
ii  libsigsegv2:arm64                  2.12-1                             arm64        Library for handling page faults in a portable way
ii  libslang2:arm64                    2.3.1a-3ubuntu1                    arm64        S-Lang programming library - runtime version
ii  libsm6:arm64                       2:1.2.2-1                          arm64        X11 Session Management library
ii  libsmartcols1:arm64                2.31.1-0.4ubuntu3.4                arm64        smart column output alignment library
ii  libsnappy1v5:arm64                 1.1.7-1                            arm64        fast compression/decompression library
ii  libsndfile1:arm64                  1.0.28-4ubuntu0.18.04.1            arm64        Library for reading/writing audio files
ii  libsodium23:arm64                  1.0.16-2                           arm64        Network communication, cryptography and signaturing library
ii  libsqlite3-0:arm64                 3.22.0-1ubuntu0.1                  arm64        SQLite 3 shared library
ii  libss2:arm64                       1.44.1-1ubuntu1.2                  arm64        command-line interface parsing library
ii  libssl1.0.0:arm64                  1.0.2n-1ubuntu5.3                  arm64        Secure Sockets Layer toolkit - shared libraries
ii  libssl1.1:arm64                    1.1.1-1ubuntu2.1~18.04.4           arm64        Secure Sockets Layer toolkit - shared libraries
ii  libstdc++-7-dev:armhf              7.4.0-1ubuntu1~18.04.1             armhf        GNU Standard C++ Library v3 (development files)
ii  libstdc++6:arm64                   8.3.0-6ubuntu1~18.04.1             arm64        GNU Standard C++ Library v3
ii  libstdc++6:armhf                   8.3.0-6ubuntu1~18.04.1             armhf        GNU Standard C++ Library v3
ii  libsystemd0:arm64                  237-3ubuntu10.31                   arm64        systemd utility library
ii  libtasn1-6:arm64                   4.13-2                             arm64        Manage ASN.1 structures (runtime)
ii  libtext-charwidth-perl             0.04-7.1                           arm64        get display widths of characters on the terminal
ii  libtext-iconv-perl                 1.7-5build6                        arm64        converts between character sets in Perl
ii  libtext-wrapi18n-perl              0.06-7.1                           all          internationalized substitute of Text::Wrap
ii  libthai-data                       0.1.27-2                           all          Data files for Thai language support library
ii  libthai0:arm64                     0.1.27-2                           arm64        Thai language support library
ii  libtiff5:arm64                     4.0.9-5ubuntu0.3                   arm64        Tag Image File Format (TIFF) library
ii  libtimedate-perl                   2.3000-2                           all          collection of modules to manipulate date/time information
ii  libtinfo5:arm64                    6.1-1ubuntu1.18.04                 arm64        shared low-level terminfo library for terminal handling
ii  libtsan0:arm64                     8.3.0-6ubuntu1~18.04.1             arm64        ThreadSanitizer -- a Valgrind-based detector of data races (runtime)
ii  libubsan0:armhf                    7.4.0-1ubuntu1~18.04.1             armhf        UBSan -- undefined behaviour sanitizer (runtime)
ii  libudev1:arm64                     237-3ubuntu10.31                   arm64        libudev shared library
ii  libunistring2:arm64                0.9.9-0ubuntu2                     arm64        Unicode string library for C
ii  liburi-perl                        1.73-1                             all          module to manipulate and access URI strings
ii  libusb-1.0-0:arm64                 2:1.0.21-2                         arm64        userspace USB programming library
ii  libutempter0:arm64                 1.1.6-3                            arm64        privileged helper for utmp/wtmp updates (runtime)
ii  libuuid1:arm64                     2.31.1-0.4ubuntu3.4                arm64        Universally Unique ID library
ii  libuv1:arm64                       1.18.0-3                           arm64        asynchronous event notification library - runtime library
ii  libvorbis0a:arm64                  1.3.5-4.2                          arm64        decoder library for Vorbis General Audio Compression Codec
ii  libvorbisenc2:arm64                1.3.5-4.2                          arm64        encoder library for Vorbis General Audio Compression Codec
ii  libwebp6:arm64                     0.6.1-2                            arm64        Lossy compression of digital photographic images.
ii  libwebpdemux2:arm64                0.6.1-2                            arm64        Lossy compression of digital photographic images.
ii  libwebpmux3:arm64                  0.6.1-2                            arm64        Lossy compression of digital photographic images.
ii  libwind0-heimdal:arm64             7.5.0+dfsg-1                       arm64        Heimdal Kerberos - stringprep implementation
ii  libwrap0:arm64                     7.6.q-27                           arm64        Wietse Venema's TCP wrappers library
ii  libx11-6:arm64                     2:1.6.4-3ubuntu0.2                 arm64        X11 client-side library
ii  libx11-data                        2:1.6.4-3ubuntu0.2                 all          X11 client-side library
ii  libx11-xcb1:arm64                  2:1.6.4-3ubuntu0.2                 arm64        Xlib/XCB interface library
ii  libxau6:arm64                      1:1.0.8-1                          arm64        X11 authorisation library
ii  libxaw7:arm64                      2:1.0.13-1                         arm64        X11 Athena Widget library
ii  libxcb-dri2-0:arm64                1.13-2~ubuntu18.04                 arm64        X C Binding, dri2 extension
ii  libxcb-dri3-0:arm64                1.13-2~ubuntu18.04                 arm64        X C Binding, dri3 extension
ii  libxcb-glx0:arm64                  1.13-2~ubuntu18.04                 arm64        X C Binding, glx extension
ii  libxcb-present0:arm64              1.13-2~ubuntu18.04                 arm64        X C Binding, present extension
ii  libxcb-render0:arm64               1.13-2~ubuntu18.04                 arm64        X C Binding, render extension
ii  libxcb-shape0:arm64                1.13-2~ubuntu18.04                 arm64        X C Binding, shape extension
ii  libxcb-shm0:arm64                  1.13-2~ubuntu18.04                 arm64        X C Binding, shm extension
ii  libxcb-sync1:arm64                 1.13-2~ubuntu18.04                 arm64        X C Binding, sync extension
ii  libxcb1:arm64                      1.13-2~ubuntu18.04                 arm64        X C Binding
ii  libxcomposite1:arm64               1:0.4.4-2                          arm64        X11 Composite extension library
ii  libxcursor1:arm64                  1:1.1.15-1                         arm64        X cursor management library
ii  libxdamage1:arm64                  1:1.1.4-3                          arm64        X11 damaged region extension library
ii  libxdmcp6:arm64                    1:1.1.2-3                          arm64        X11 Display Manager Control Protocol library
ii  libxext6:arm64                     2:1.3.3-1                          arm64        X11 miscellaneous extension library
ii  libxfixes3:arm64                   1:5.0.3-1                          arm64        X11 miscellaneous 'fixes' extension library
ii  libxft2:arm64                      2.3.2-1                            arm64        FreeType-based font drawing library for X
ii  libxi6:arm64                       2:1.7.9-1                          arm64        X11 Input extension library
ii  libxinerama1:arm64                 2:1.1.3-1                          arm64        X11 Xinerama extension library
ii  libxml2:arm64                      2.9.4+dfsg1-6.1ubuntu1.2           arm64        GNOME XML library
ii  libxmu6:arm64                      2:1.1.2-2                          arm64        X11 miscellaneous utility library
ii  libxmuu1:arm64                     2:1.1.2-2                          arm64        X11 miscellaneous micro-utility library
ii  libxpm4:arm64                      1:3.5.12-1                         arm64        X11 pixmap library
ii  libxrandr2:arm64                   2:1.5.1-1                          arm64        X11 RandR extension library
ii  libxrender1:arm64                  1:0.9.10-1                         arm64        X Rendering Extension client library
ii  libxshmfence1:arm64                1.3-1                              arm64        X shared memory fences - shared library
ii  libxslt1.1:arm64                   1.1.29-5ubuntu0.2                  arm64        XSLT 1.0 processing library - runtime library
ii  libxt6:arm64                       1:1.1.5-1                          arm64        X11 toolkit intrinsics library
ii  libxtables12:arm64                 1.6.1-2ubuntu2                     arm64        netfilter xtables library
ii  libxtst6:arm64                     2:1.2.3-1                          arm64        X11 Testing -- Record extension library
ii  libxv1:arm64                       2:1.0.11-1                         arm64        X11 Video extension library
ii  libxxf86dga1:arm64                 2:1.1.4-1                          arm64        X11 Direct Graphics Access extension library
ii  libxxf86vm1:arm64                  1:1.1.4-1                          arm64        X11 XFree86 video mode extension library
ii  libyaml-0-2:arm64                  0.1.7-2ubuntu3                     arm64        Fast YAML 1.1 parser and emitter library
ii  libzstd1:arm64                     1.3.3+dfsg-2ubuntu1.1              arm64        fast lossless compression algorithm
ii  linux-aws                          4.15.0.1052.51                     arm64        Complete Linux kernel for Amazon Web Services (AWS) systems.
ii  linux-aws-headers-4.15.0-1045      4.15.0-1045.47                     all          Header files related to Linux kernel version 4.15.0
ii  linux-aws-headers-4.15.0-1052      4.15.0-1052.54                     all          Header files related to Linux kernel version 4.15.0
ii  linux-base                         4.5ubuntu1                         all          Linux image base package
ii  linux-headers-4.15.0-1045-aws      4.15.0-1045.47                     arm64        Linux kernel headers for version 4.15.0 on ARMv8 SMP
ii  linux-headers-4.15.0-1052-aws      4.15.0-1052.54                     arm64        Linux kernel headers for version 4.15.0 on ARMv8 SMP
ii  linux-headers-aws                  4.15.0.1052.51                     arm64        Linux kernel headers for Amazon Web Services (AWS) systems.
ii  linux-image-4.15.0-1045-aws        4.15.0-1045.47                     arm64        Linux kernel image for version 4.15.0 on ARMv8 SMP
ii  linux-image-4.15.0-1052-aws        4.15.0-1052.54                     arm64        Linux kernel image for version 4.15.0 on ARMv8 SMP
ii  linux-image-aws                    4.15.0.1052.51                     arm64        Linux kernel image for Amazon Web Services (AWS) systems.
ii  linux-libc-dev:arm64               4.15.0-66.75                       arm64        Linux Kernel Headers for development
ii  linux-libc-dev:armhf               4.15.0-66.75                       armhf        Linux Kernel Headers for development
ii  linux-modules-4.15.0-1045-aws      4.15.0-1045.47                     arm64        Linux kernel extra modules for version 4.15.0 on ARMv8 SMP
ii  linux-modules-4.15.0-1052-aws      4.15.0-1052.54                     arm64        Linux kernel extra modules for version 4.15.0 on ARMv8 SMP
ii  locales                            2.27-3ubuntu1                      all          GNU C Library: National Language (locale) data [support]
ii  login                              1:4.5-1ubuntu2                     arm64        system login tools
ii  logrotate                          3.11.0-0.1ubuntu1                  arm64        Log rotation utility
ii  lsb-base                           9.20170808ubuntu1                  all          Linux Standard Base init script functionality
ii  lsb-release                        9.20170808ubuntu1                  all          Linux Standard Base version reporting utility
ii  lshw                               02.18-0.1ubuntu6.18.04.1           arm64        information about hardware configuration
ii  lsof                               4.89+dfsg-0.1                      arm64        Utility to list open files
ii  ltrace                             0.7.3-6ubuntu1                     arm64        Tracks runtime library calls in dynamically linked programs
ii  lvm2                               2.02.176-4.1ubuntu3.18.04.1        arm64        Linux Logical Volume Manager
ii  lxcfs                              3.0.3-0ubuntu1~18.04.1             arm64        FUSE based filesystem for LXC
ii  lxd                                3.0.3-0ubuntu1~18.04.1             arm64        Container hypervisor based on LXC - daemon
ii  lxd-client                         3.0.3-0ubuntu1~18.04.1             arm64        Container hypervisor based on LXC - client
ii  m4                                 1.4.18-1                           arm64        macro processing language
ii  make:armhf                         4.1-9.1ubuntu1                     armhf        utility for directing compilation
ii  man-db                             2.8.3-2ubuntu0.1                   arm64        on-line manual pager
ii  manpages                           4.15-1                             all          Manual pages about using a GNU/Linux system
ii  manpages-dev                       4.15-1                             all          Manual pages about using GNU/Linux for development
ii  mawk                               1.3.3-17ubuntu3                    arm64        a pattern scanning and text processing language
ii  mdadm                              4.1~rc1-3~ubuntu18.04.2            arm64        tool to administer Linux MD arrays (software RAID)
ii  mime-support                       3.60ubuntu1                        all          MIME files 'mime.types' & 'mailcap', and support programs
ii  mlocate                            0.26-2ubuntu3.1                    arm64        quickly find files on the filesystem based on their name
ii  mount                              2.31.1-0.4ubuntu3.4                arm64        tools for mounting and manipulating filesystems
ii  mtd-utils                          1:2.0.1-1ubuntu3                   arm64        Memory Technology Device Utilities
ii  mtr-tiny                           0.92-1                             arm64        Full screen ncurses traceroute tool
ii  multiarch-support                  2.27-3ubuntu1                      arm64        Transitional package to ensure multiarch compatibility
ii  mysql-client-5.7                   5.7.27-0ubuntu0.18.04.1            arm64        MySQL database client binaries
ii  mysql-client-core-5.7              5.7.27-0ubuntu0.18.04.1            arm64        MySQL database core client binaries
ii  mysql-common                       5.8+1.0.4                          all          MySQL database common files, e.g. /etc/mysql/my.cnf
ii  mysql-server                       5.7.27-0ubuntu0.18.04.1            all          MySQL database server (metapackage depending on the latest version)
ii  mysql-server-5.7                   5.7.27-0ubuntu0.18.04.1            arm64        MySQL database server binaries and system database setup
ii  mysql-server-core-5.7              5.7.27-0ubuntu0.18.04.1            arm64        MySQL database server binaries
ii  nano                               2.9.3-2                            arm64        small, friendly text editor inspired by Pico
ii  ncurses-base                       6.1-1ubuntu1.18.04                 all          basic terminal type definitions
ii  ncurses-bin                        6.1-1ubuntu1.18.04                 arm64        terminal-related programs and man pages
ii  ncurses-term                       6.1-1ubuntu1.18.04                 all          additional terminal type definitions
ii  net-tools                          1.60+git20161116.90da8a0-1ubuntu1  arm64        NET-3 networking toolkit
ii  netbase                            5.4                                all          Basic TCP/IP networking system
ii  netcat-openbsd                     1.187-1ubuntu0.1                   arm64        TCP/IP swiss army knife
ii  netplan.io                         0.98-0ubuntu1~18.04.1              arm64        YAML network configuration abstraction for various backends
ii  networkd-dispatcher                1.7-0ubuntu3.3                     all          Dispatcher service for systemd-networkd connection status changes
ii  nginx                              1.14.0-0ubuntu1.6                  all          small, powerful, scalable web/proxy server
ii  nginx-common                       1.14.0-0ubuntu1.6                  all          small, powerful, scalable web/proxy server - common files
ii  nginx-core                         1.14.0-0ubuntu1.6                  arm64        nginx web/proxy server (standard version)
ii  nplan                              0.98-0ubuntu1~18.04.1              all          YAML network configuration abstraction - transitional package
ii  ntfs-3g                            1:2017.3.23-2ubuntu0.18.04.2       arm64        read/write NTFS driver for FUSE
ii  open-iscsi                         2.0.874-5ubuntu2.7                 arm64        iSCSI initiator tools
ii  openjdk-11-jre:arm64               11.0.4+11-1ubuntu2~18.04.3         arm64        OpenJDK Java runtime, using Hotspot JIT
ii  openjdk-11-jre-headless:arm64      11.0.4+11-1ubuntu2~18.04.3         arm64        OpenJDK Java runtime, using Hotspot JIT (headless)
ii  openjdk-8-jre:arm64                8u222-b10-1ubuntu1~18.04.1         arm64        OpenJDK Java runtime, using Hotspot JIT
ii  openjdk-8-jre-headless:arm64       8u222-b10-1ubuntu1~18.04.1         arm64        OpenJDK Java runtime, using Hotspot JIT (headless)
ii  openssh-client                     1:7.6p1-4ubuntu0.3                 arm64        secure shell (SSH) client, for secure access to remote machines
ii  openssh-server                     1:7.6p1-4ubuntu0.3                 arm64        secure shell (SSH) server, for secure access from remote machines
ii  openssh-sftp-server                1:7.6p1-4ubuntu0.3                 arm64        secure shell (SSH) sftp server module, for SFTP access from remote machines
ii  openssl                            1.1.1-1ubuntu2.1~18.04.4           arm64        Secure Sockets Layer toolkit - cryptographic utility
ii  overlayroot                        0.40ubuntu1.1                      all          use an overlayfs on top of a read-only root filesystem
ii  parted                             3.2-20ubuntu0.2                    arm64        disk partition manipulator
ii  passwd                             1:4.5-1ubuntu2                     arm64        change and administer password and group data
ii  pastebinit                         1.5-2                              all          command-line pastebin client
ii  patch                              2.7.6-2ubuntu1.1                   arm64        Apply a diff file to an original
ii  pciutils                           1:3.5.2-1ubuntu1.1                 arm64        Linux PCI Utilities
ii  perl                               5.26.1-6ubuntu0.3                  arm64        Larry Wall's Practical Extraction and Report Language
ii  perl-base                          5.26.1-6ubuntu0.3                  arm64        minimal Perl system
ii  perl-modules-5.26                  5.26.1-6ubuntu0.3                  all          Core Perl modules
ii  php-common                         1:60ubuntu1                        all          Common files for PHP packages
ii  php7.2                             7.2.24-0ubuntu0.18.04.1            all          server-side, HTML-embedded scripting language (metapackage)
ii  php7.2-cli                         7.2.24-0ubuntu0.18.04.1            arm64        command-line interpreter for the PHP scripting language
ii  php7.2-common                      7.2.24-0ubuntu0.18.04.1            arm64        documentation, examples and common module for PHP
ii  php7.2-fpm                         7.2.24-0ubuntu0.18.04.1            arm64        server-side, HTML-embedded scripting language (FPM-CGI binary)
ii  php7.2-gd                          7.2.24-0ubuntu0.18.04.1            arm64        GD module for PHP
ii  php7.2-json                        7.2.24-0ubuntu0.18.04.1            arm64        JSON module for PHP
ii  php7.2-mysql                       7.2.24-0ubuntu0.18.04.1            arm64        MySQL module for PHP
ii  php7.2-opcache                     7.2.24-0ubuntu0.18.04.1            arm64        Zend OpCache module for PHP
ii  php7.2-readline                    7.2.24-0ubuntu0.18.04.1            arm64        readline module for PHP
ii  pinentry-curses                    1.1.0-1                            arm64        curses-based PIN or pass-phrase entry dialog for GnuPG
ii  plymouth                           0.9.3-1ubuntu7.18.04.2             arm64        boot animation, logger and I/O multiplexer
ii  plymouth-theme-ubuntu-text         0.9.3-1ubuntu7.18.04.2             arm64        boot animation, logger and I/O multiplexer - ubuntu text theme
ii  policykit-1                        0.105-20ubuntu0.18.04.5            arm64        framework for managing administrative policies and privileges
ii  pollinate                          4.33-0ubuntu1~18.04.1              all          seed the pseudo random number generator
ii  popularity-contest                 1.66ubuntu1                        all          Vote for your favourite packages automatically
ii  powermgmt-base                     1.33                               all          common utils for power management
ii  procps                             2:3.3.12-3ubuntu1.2                arm64        /proc file system utilities
ii  psmisc                             23.1-1ubuntu0.1                    arm64        utilities that use the proc file system
ii  publicsuffix                       20180223.1310-1                    all          accurate, machine-readable list of domain name suffixes
ii  python-apt-common                  1.6.4                              all          Python interface to libapt-pkg (locales)
ii  python-certbot-nginx               0.31.0-1+ubuntu18.04.1+certbot+1   all          transitional dummy package
ii  python3                            3.6.7-1~18.04                      arm64        interactive high-level object-oriented language (default python3 version)
ii  python3-acme                       0.31.0-2+ubuntu18.04.3+certbot+2   all          ACME protocol library for Python 3
ii  python3-apport                     2.20.9-0ubuntu7.8                  all          Python 3 library for Apport crash report handling
ii  python3-apt                        1.6.4                              arm64        Python 3 interface to libapt-pkg
ii  python3-asn1crypto                 0.24.0-1                           all          Fast ASN.1 parser and serializer (Python 3)
ii  python3-attr                       17.4.0-2                           all          Attributes without boilerplate (Python 3)
ii  python3-autobahn                   17.10.1+dfsg1-2                    all          WebSocket client and server library, WAMP framework - Python 3.x
ii  python3-automat                    0.6.0-1                            all          Self-service finite-state machines for the programmer on the go
ii  python3-blinker                    1.4+dfsg1-0.1                      all          fast, simple object-to-object and broadcast signaling library
ii  python3-buildbot                   1.1.1-3ubuntu5                     all          System to automate the compile/test cycle (server)
ii  python3-buildbot-worker            1.1.1-3ubuntu5                     all          System to automate the compile/test cycle (worker agent)
ii  python3-cbor                       1.0.0-1                            arm64        Python3 Implementation of RFC 7049. Concise Binary Object Representation (CBOR)
ii  python3-certbot                    0.31.0-1+ubuntu18.04.1+certbot+1   all          main library for certbot
ii  python3-certbot-nginx              0.31.0-1+ubuntu18.04.1+certbot+1   all          Nginx plugin for Certbot
ii  python3-certifi                    2018.1.18-2                        all          root certificates for validating SSL certs and verifying TLS hosts (python3)
ii  python3-cffi-backend               1.11.5-1                           arm64        Foreign Function Interface for Python 3 calling C code - runtime
ii  python3-chardet                    3.0.4-1                            all          universal character encoding detector for Python3
ii  python3-click                      6.7-3                              all          Simple wrapper around optparse for powerful command line utilities - Python 3.x
ii  python3-colorama                   0.3.7-1                            all          Cross-platform colored terminal text in Python - Python 3.x
ii  python3-commandnotfound            18.04.5                            all          Python 3 bindings for command-not-found.
ii  python3-configargparse             0.11.0-1                           all          replacement for argparse with config files and environment variables (Python 3)
ii  python3-configobj                  5.0.6-2                            all          simple but powerful config file reader and writer for Python 3
ii  python3-constantly                 15.1.0-1                           all          Symbolic constants in Python
ii  python3-cryptography               2.1.4-1ubuntu1.3                   arm64        Python library exposing cryptographic recipes and primitives (Python 3)
ii  python3-dateutil                   2.6.1-1                            all          powerful extensions to the standard Python 3 datetime module
ii  python3-dbus                       1.2.6-1                            arm64        simple interprocess messaging system (Python 3 interface)
ii  python3-debconf                    1.5.66ubuntu1                      all          interact with debconf from Python 3
ii  python3-debian                     0.1.32                             all          Python 3 modules to work with Debian-related data formats
ii  python3-decorator                  4.1.2-1                            all          simplify usage of Python decorators by programmers
ii  python3-dev                        3.6.7-1~18.04                      arm64        header files and a static library for Python (default)
ii  python3-distro-info                0.18ubuntu0.18.04.1                all          information about distributions' releases (Python 3 module)
ii  python3-distupgrade                1:18.04.34                         all          manage release upgrades
ii  python3-distutils                  3.6.8-1~18.04                      all          distutils package for Python 3.x
ii  python3-future                     0.15.2-4ubuntu2                    all          Clean single-source support for Python 3 and 2 - Python 3.x
ii  python3-gdbm:arm64                 3.6.8-1~18.04                      arm64        GNU dbm database support for Python 3.x
ii  python3-gi                         3.26.1-2ubuntu1                    arm64        Python 3 bindings for gobject-introspection libraries
ii  python3-httplib2                   0.9.2+dfsg-1ubuntu0.1              all          comprehensive HTTP client library written for Python3
ii  python3-hyperlink                  17.3.1-2                           all          Immutable, Pythonic, correct URLs.
ii  python3-icu                        1.9.8-0ubuntu1                     arm64        Python 3 extension wrapping the ICU C++ API
ii  python3-idna                       2.6-1                              all          Python IDNA2008 (RFC 5891) handling (Python 3)
ii  python3-incremental                16.10.1-3                          all          Library for versioning Python projects.
ii  python3-jinja2                     2.10-1ubuntu0.18.04.1              all          small but fast and easy to use stand-alone template engine
ii  python3-josepy                     1.1.0-2+ubuntu18.04.1+certbot+1    all          JOSE implementation for Python 3.x
ii  python3-json-pointer               1.10-1                             all          resolve JSON pointers - Python 3.x
ii  python3-jsonpatch                  1.19+really1.16-1fakesync1         all          library to apply JSON patches - Python 3.x
ii  python3-jsonschema                 2.6.0-2                            all          An(other) implementation of JSON Schema (Draft 3 and 4) - Python 3.x
ii  python3-jwt                        1.5.3+ds1-1                        all          Python 3 implementation of JSON Web Token
ii  python3-lib2to3                    3.6.8-1~18.04                      all          Interactive high-level object-oriented language (2to3, version 3.6)
ii  python3-lz4                        0.10.1+dfsg1-0.2                   arm64        Python interface to the lz4 compression library (Python 3)
ii  python3-markupsafe                 1.0-1build1                        arm64        HTML/XHTML/XML string library for Python 3
ii  python3-migrate                    0.11.0-2                           all          Database schema migration for SQLAlchemy - Python 3.x
ii  python3-minimal                    3.6.7-1~18.04                      arm64        minimal subset of the Python language (default python3 version)
ii  python3-mock                       2.0.0-3                            all          Mocking and Testing Library (Python3 version)
ii  python3-nacl                       1.1.2-1build1                      arm64        Python bindings to libsodium (Python 3)
ii  python3-ndg-httpsclient            0.4.4-1                            all          enhanced HTTPS support for httplib and urllib2 using PyOpenSSL for Python3
ii  python3-netifaces                  0.10.4-0.1build4                   arm64        portable network interface information - Python 3.x
ii  python3-newt:arm64                 0.52.20-1ubuntu1                   arm64        NEWT module for Python3
ii  python3-oauthlib                   2.0.6-1                            all          generic, spec-compliant implementation of OAuth for Python3
ii  python3-olefile                    0.45.1-1                           all          Python module to read/write MS OLE2 files
ii  python3-openssl                    17.5.0-1ubuntu1                    all          Python 3 wrapper around the OpenSSL library
ii  python3-pam                        0.4.2-13.2ubuntu4                  arm64        Python interface to the PAM library
ii  python3-parsedatetime              2.4-3+ubuntu18.04.1+certbot+3      all          Python 3 module to parse human-readable date/time expressions
ii  python3-pbr                        3.1.1-3ubuntu3                     all          inject useful and sensible default behaviors into setuptools - Python 3.x
ii  python3-pil:arm64                  5.1.0-1                            arm64        Python Imaging Library (Python3)
ii  python3-pkg-resources              39.0.1-2                           all          Package Discovery and Resource Access using pkg_resources
ii  python3-problem-report             2.20.9-0ubuntu7.8                  all          Python 3 library to handle problem reports
ii  python3-pyasn1                     0.4.2-3                            all          ASN.1 library for Python (Python 3 module)
ii  python3-pyasn1-modules             0.2.1-0.2                          all          Collection of protocols modules written in ASN.1 language (Python 3)
ii  python3-pyparsing                  2.2.0+dfsg1-2                      all          alternative to creating and executing simple grammars - Python 3.x
ii  python3-qrcode                     5.3-1                              all          QR Code image generator library - Python 3.x
ii  python3-requests                   2.18.4-2ubuntu0.1                  all          elegant and simple HTTP library for Python3, built for human beings
ii  python3-requests-toolbelt          0.8.0-1+ubuntu18.04.1+certbot+1    all          Utility belt for advanced users of python3-requests
ii  python3-requests-unixsocket        0.1.5-3                            all          Use requests to talk HTTP via a UNIX domain socket - Python 3.x
ii  python3-rfc3339                    1.0-4                              all          parser and generator of RFC 3339-compliant timestamps (Python 3)
ii  python3-serial                     3.4-2                              all          pyserial - module encapsulating access for the serial port
ii  python3-service-identity           16.0.0-2                           all          Service identity verification for pyOpenSSL (Python 3 module)
ii  python3-six                        1.11.0-2                           all          Python 2 and 3 compatibility library (Python 3 interface)
ii  python3-snappy                     0.5-1.1build2                      arm64        snappy compression library from Google - Python 3.x
ii  python3-software-properties        0.96.24.32.11                      all          manage the repositories that you install software from
ii  python3-sqlalchemy                 1.1.11+ds1-1ubuntu1                all          SQL toolkit and Object Relational Mapper for Python 3
ii  python3-sqlparse                   0.2.4-0.1                          all          non-validating SQL parser for Python 3
ii  python3-systemd                    234-1build1                        arm64        Python 3 bindings for systemd
ii  python3-tempita                    0.5.2-2                            all          very small text templating language
ii  python3-trie                       0.2+ds-1                           all          Pure Python implementation of the trie data structure (Python 3)
ii  python3-twisted                    17.9.0-2                           all          Event-based framework for internet applications
ii  python3-twisted-bin:arm64          17.9.0-2                           arm64        Event-based framework for internet applications
ii  python3-txaio                      2.8.1-1                            all          compatibility API between asyncio/Twisted/Trollius - Python 3.x
ii  python3-tz                         2018.3-2                           all          Python3 version of the Olson timezone database
ii  python3-u-msgpack                  2.1-1                              all          Python3 MessagePack serializer and deserializer
ii  python3-ubjson                     0.8.5-2build1                      arm64        Universal Binary JSON encoder/decoder for Python 3
ii  python3-update-manager             1:18.04.11.10                      all          python 3.x module for update-manager
ii  python3-urllib3                    1.22-1ubuntu0.18.04.1              all          HTTP library with thread-safe connection pooling for Python3
ii  python3-wsaccel                    0.6.2-1                            arm64        Accelerator for ws4py and AutobahnPython - Python 3.x
ii  python3-yaml                       3.12-1build2                       arm64        YAML parser and emitter for Python3
ii  python3-zope.component             4.3.0-1+ubuntu18.04.1+certbot+3    all          Zope Component Architecture
ii  python3-zope.event                 4.2.0-1                            all          Very basic event publishing system
ii  python3-zope.hookable              4.0.4-4+ubuntu18.04.1+certbot+1    arm64        Hookable object support
ii  python3-zope.interface             4.3.2-1build2                      arm64        Interfaces for Python3
ii  python3.6                          3.6.8-1~18.04.3                    arm64        Interactive high-level object-oriented language (version 3.6)
ii  python3.6-dev                      3.6.8-1~18.04.3                    arm64        Header files and a static library for Python (v3.6)
ii  python3.6-minimal                  3.6.8-1~18.04.3                    arm64        Minimal subset of the Python language (version 3.6)
ii  readline-common                    7.0-3                              all          GNU readline and history libraries, common files
ii  rsync                              3.1.2-2.1ubuntu1                   arm64        fast, versatile, remote (and local) file-copying tool
ii  rsyslog                            8.32.0-1ubuntu4                    arm64        reliable system and kernel logging daemon
ii  run-one                            1.17-0ubuntu1                      all          run just one instance of a command and its args at a time
ii  screen                             4.6.2-1ubuntu1                     arm64        terminal multiplexer with VT100/ANSI terminal emulation
ii  sed                                4.4-2                              arm64        GNU stream editor for filtering/transforming text
ii  sensible-utils                     0.0.12                             all          Utilities for sensible alternative selection
ii  shared-mime-info                   1.9-2                              arm64        FreeDesktop.org shared MIME database and spec
ii  snapd                              2.40+18.04                         arm64        Daemon and tooling that enable snap packages
ii  software-properties-common         0.96.24.32.11                      all          manage the repositories that you install software from (common)
ii  sosreport                          3.6-1ubuntu0.18.04.3               arm64        Set of tools to gather troubleshooting data from a system
ii  squashfs-tools                     1:4.3-6ubuntu0.18.04.1             arm64        Tool to create and append to squashfs filesystems
ii  ssh-import-id                      5.7-0ubuntu1.1                     all          securely retrieve an SSH public key and install it locally
ii  strace                             4.21-1ubuntu1                      arm64        System call tracer
ii  sudo                               1.8.21p2-3ubuntu1.1                arm64        Provide limited super user privileges to specific users
ii  systemd                            237-3ubuntu10.31                   arm64        system and service manager
ii  systemd-sysv                       237-3ubuntu10.31                   arm64        system and service manager - SysV links
ii  sysvinit-utils                     2.88dsf-59.10ubuntu1               arm64        System-V-like utilities
ii  tar                                1.29b-2ubuntu0.1                   arm64        GNU version of the tar archiving utility
ii  tcpdump                            4.9.2-3                            arm64        command-line network traffic analyzer
ii  telnet                             0.17-41                            arm64        basic telnet client
ii  time                               1.7-25.1build1                     arm64        GNU time program for measuring CPU resource usage
ii  tmux                               2.6-3ubuntu0.2                     arm64        terminal multiplexer
ii  tzdata                             2019c-0ubuntu0.18.04               all          time zone and daylight-saving time data
ii  ubuntu-advantage-tools             17                                 all          management tools for Ubuntu Advantage
ii  ubuntu-keyring                     2018.09.18.1~18.04.0               all          GnuPG keys of the Ubuntu archive
ii  ubuntu-minimal                     1.417.3                            arm64        Minimal core of Ubuntu
ii  ubuntu-mono                        16.10+18.04.20181005-0ubuntu1      all          Ubuntu Mono Icon theme
ii  ubuntu-release-upgrader-core       1:18.04.34                         all          manage release upgrades
ii  ubuntu-server                      1.417.3                            arm64        The Ubuntu Server system
ii  ubuntu-standard                    1.417.3                            arm64        The Ubuntu standard system
ii  ucf                                3.0038                             all          Update Configuration File(s): preserve user changes to config files
ii  udev                               237-3ubuntu10.31                   arm64        /dev/ and hotplug management daemon
ii  ufw                                0.36-0ubuntu0.18.04.1              all          program for managing a Netfilter firewall
ii  uidmap                             1:4.5-1ubuntu2                     arm64        programs to help use subuids
ii  unattended-upgrades                1.1ubuntu1.18.04.11                all          automatic installation of security upgrades
ii  update-manager-core                1:18.04.11.10                      all          manage release upgrades
ii  update-notifier-common             3.192.1.7                          all          Files shared between update-notifier and other packages
ii  ureadahead                         0.100.0-21                         arm64        Read required files in advance
ii  usbutils                           1:007-4build1                      arm64        Linux USB utilities
ii  util-linux                         2.31.1-0.4ubuntu3.4                arm64        miscellaneous system utilities
ii  uuid-runtime                       2.31.1-0.4ubuntu3.4                arm64        runtime components for the Universally Unique ID library
ii  vim                                2:8.0.1453-1ubuntu1.1              arm64        Vi IMproved - enhanced vi editor
ii  vim-common                         2:8.0.1453-1ubuntu1.1              all          Vi IMproved - Common files
ii  vim-runtime                        2:8.0.1453-1ubuntu1.1              all          Vi IMproved - Runtime files
ii  vim-tiny                           2:8.0.1453-1ubuntu1.1              arm64        Vi IMproved - enhanced vi editor - compact version
ii  wget                               1.19.4-1ubuntu2.2                  arm64        retrieves files from the web
ii  whiptail                           0.52.20-1ubuntu1                   arm64        Displays user-friendly dialog boxes from shell scripts
ii  x11-common                         1:7.7+19ubuntu7.1                  all          X Window System (X.Org) infrastructure
ii  x11-utils                          7.7+3build1                        arm64        X11 utilities
ii  xauth                              1:1.0.10-1                         arm64        X authentication utility
ii  xdelta3                            3.0.11-dfsg-1ubuntu1               arm64        Diff utility which works with binary files
ii  xdg-user-dirs                      0.17-1ubuntu1                      arm64        tool to manage well known user directories
ii  xfsprogs                           4.9.0+nmu1ubuntu2                  arm64        Utilities for managing the XFS filesystem
ii  xkb-data                           2.23.1-1ubuntu1.18.04.1            all          X Keyboard Extension (XKB) configuration data
ii  xxd                                2:8.0.1453-1ubuntu1.1              arm64        tool to make (or reverse) a hex dump
ii  xz-utils                           5.2.2-1.3                          arm64        XZ-format compression utilities
ii  zlib1g:arm64                       1:1.2.11.dfsg-0ubuntu2             arm64        compression library - runtime
ii  zlib1g:armhf                       1:1.2.11.dfsg-0ubuntu2             armhf        compression library - runtimeDesired=Unknown/Install/Remove/Purge/Hold
```

