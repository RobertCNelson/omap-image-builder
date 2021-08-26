Generating Images
=================

Production Test Image
---------------------

```
$ ./RootStock-NG.sh -c octavo-debian-buster-test-v4.19.conf
```

Console Image
-------------

```
$ ./RootStock-NG.sh -c octavo-debian-buster-console-v4.19.conf
```

LXQT Image
----------

```
$ ./RootStock-NG.sh -c octavo-debian-buster-lxqt-v4.19
```

Flashing Images
===============

Production Test Image
---------------------

```
$ cd deploy/debian-10.3-test-armhf-YYYY-MM-DD
$ sudo ./setup_sdcard.sh --mmc /dev/sdX --dtb hwpack/octavo-blank-eeprom.conf
```

Console Image
-------------

```
$ cd deploy/debian-10.3-console-armhf-YYYY-MM-DD
$ sudo ./setup_sdcard.sh --mmc /dev/sdX --dtb hwpack/octavo.conf
```

LXQT Image
----------

```
$ cd deploy/debian-10.3-lxqt-armhf-YYYY-MM-DD
$ sudo ./setup_sdcard.sh --mmc /dev/sdX --dtb hwpack/octavo.conf
```

Generate Image File
-------------------

```
$ cd deploy/debian-10.3-TYPE-armhf-YYYY-MM-DD
$ sudo ./setup_sh.sh --img-4gb image-name-here --dtb hwpack/[octavo|octavo-blank-eeprom].conf
```
