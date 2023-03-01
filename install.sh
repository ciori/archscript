#!/bin/bash

MIRRORLIST_COUNTRY=
DISK=
TIME_ZONE=
HOSTNAME=
CPU_BRAND= # "amd" or "intel"
GRUB_BOOTLOADER_ID=
USERNAME=

# INITIAL PACMAN SETUP

reflector --country $MIRRORLIST_COUNTRY --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -i 's/#Color/Color/g' /etc/pacman.conf
sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf
pacman -Syy

# SETUP DISK AND FILE SYSTEM

fdisk $DISK <<EOF
g
n
1

+512M
t
1
n
2


t
2
20
w
EOF
# encryption
mkfs.vfat ${DISK}1
mkfs.btrfs ${DISK}2
mount ${DISK}2 /mnt
cd /mnt
btrfs su cr @
btrfs su cr @cache
btrfs su cr @home
btrfs su cr @log
btrfs su cr @snapshots
cd
umount /mnt
mount -o compress=zstd:1,noatime,subvol=@ ${DISK}2 /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@home ${DISK}2 /mnt/home
mount -o compress=zstd:1,noatime,subvol=@snapshots ${DISK}2 /mnt/.snapshots
mount -o compress=zstd:1,noatime,subvol=@cache ${DISK}2 /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@log ${DISK}2 /mnt/var/log
mount ${DISK}1 /mnt/boot/efi

# INITIAL BOOTSTRAP

pacstrap -K /mnt base linux linux-firmware base-devel git reflector
genfstab -U /mnt >> /mnt/etc/fstab
chmod +x /afterchroot-script.sh
cp ./afterchroot-script.sh /mnt/afterchroot-script.sh
sed -i "s/MIRRORLIST_COUNTRY=/MIRRORLIST_COUNTRY=${MIRRORLIST_COUNTRY}/g" ./afterchroot-script.sh
sed -i "s/DISK=/DISK=${DISK}/g" ./afterchroot-script.sh
sed -i "s/TIME_ZONE=/TIME_ZONE=${TIME_ZONE}/g" ./afterchroot-script.sh
sed -i "s/HOSTNAME=/HOSTNAME=${HOSTNAME}/g" ./afterchroot-script.sh
sed -i "s/MIRRORLIST_COUNTRY=/MIRRORLIST_COUNTRY=${MIRRORLIST_COUNTRY}/g" ./afterchroot-script.sh
sed -i "s/CPU_BRAND=/CPU_BRAND=${CPU_BRAND}/g" ./afterchroot-script.sh
sed -i "s/GRUB_BOOTLOADER_ID=/GRUB_BOOTLOADER_ID=${GRUB_BOOTLOADER_ID}/g" ./afterchroot-script.sh
sed -i "s/USERNAME=/USERNAME=${USERNAME}/g" ./afterchroot-script.sh
arch-chroot /mnt ./afterchroot-script.sh