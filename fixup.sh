#!/bin/bash
set -e

cat > /etc/e2fsck.conf <<EOF
[problems]

# Superblock last mount time is in the future (PR_0_FUTURE_SB_LAST_MOUNT).
0x000031 = {
    preen_ok = true
    preen_nomessage = true
} 

# Superblock last write time is in the future (PR_0_FUTURE_SB_LAST_WRITE).
0x000032 = {
    preen_ok = true
    preen_nomessage = true
}

EOF

echo "/dev/mmcblk0p2   /   auto   errors=remount-ro   0   1" >> /etc/fstab


