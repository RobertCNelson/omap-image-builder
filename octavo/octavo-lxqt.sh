#!/bin/sh

sudo cp -v "${DIR}/octavo/wallpapers/OSD3358-SM-RED-Background-Circuits.png" "${tempdir}/opt/scripts/images/wallpaper.png"
sudo chown root:root "${tempdir}/opt/scripts/images/wallpaper.png"

sudo cat "${tempdir}/home/debian/.config/pcmanfm-qt/lxqt/settings.conf" | sed s/beaglebg.jpg/wallpaper.png/ > ${DIR}/tmp.settings
sudo mv "${DIR}/tmp.settings" "${tempdir}/home/debian/.config/pcmanfm-qt/lxqt/settings.conf"
