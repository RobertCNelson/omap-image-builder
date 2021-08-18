#!/bin/sh

sudo cp -v "${DIR}/octavo/scripts/eeprom_program.sh" "${tempdir}/usr/bin/eeprom_program.sh"
sudo chmod 755 "${tempdir}/usr/bin/eeprom_program.sh"
sudo chown root:root "${tempdir}/usr/bin/eeprom_program.sh"

sudo mkdir -p "${tempdir}/opt/eeprom"
sudo cp -v "${DIR}/octavo/eeprom/bbb-eeprom.dump" "${tempdir}/opt/eeprom/bbb-eeprom.dump"
sudo chown -R root:root "${tempdir}/opt/eeprom"

sudo cp -v "${DIR}/octavo/services/eeprom_program.service" "${tempdir}/lib/systemd/system/eeprom_program.service"
sudo chown root:root "${tempdir}/lib/systemd/system/eeprom_program.service" || true

sudo cp -v "${DIR}/octavo/services/osdtester.service" "${tempdir}/lib/systemd/system/osdtester.service"
sudo chown root:root "${tempdir}/lib/systemd/system/osdtester.service"

sudo ln -s "/lib/systemd/system/eeprom_program.service" "${tempdir}/etc/systemd/system/multi-user.target.wants/eeprom_program.service"
sudo chown --no-dereference root:root "${tempdir}/etc/systemd/system/multi-user.target.wants/eeprom_program.service"

sudo ln -s "/lib/systemd/system/osdtester.service" "${tempdir}/etc/systemd/system/multi-user.target.wants/osdtester.service"
sudo chown --no-dereference root:root "${tempdir}/etc/systemd/system/multi-user.target.wants/osdtester.service"
