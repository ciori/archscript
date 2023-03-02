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
cryptsetup luksFormat ${DISK}2
cryptsetup luksOpen ${DISK}2 cryptroot
mkfs.vfat ${DISK}1
mkfs.btrfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
cd /mnt
btrfs su cr @
btrfs su cr @cache
btrfs su cr @home
btrfs su cr @log
btrfs su cr @snapshots
cd
umount /mnt
mount -o compress=zstd:1,noatime,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o compress=zstd:1,noatime,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o compress=zstd:1,noatime,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount ${DISK}1 /mnt/boot/efi

# INITIAL BOOTSTRAP

pacstrap -K /mnt base linux linux-firmware base-devel git reflector
genfstab -U /mnt >> /mnt/etc/fstab
chmod +x /root/archscript/chroot.sh
sed -i "s@MIRRORLIST_COUNTRY=@MIRRORLIST_COUNTRY=${MIRRORLIST_COUNTRY}@g" /root/archscript/chroot.sh
sed -i "s@DISK=@DISK=${DISK}@g" /root/archscript/chroot.sh
sed -i "s@TIME_ZONE=@TIME_ZONE=${TIME_ZONE}@g" /root/archscript/chroot.sh
sed -i "s@HOSTNAME=@HOSTNAME=${HOSTNAME}@g" /root/archscript/chroot.sh
sed -i "s@CPU_BRAND=@CPU_BRAND=${CPU_BRAND}@g" /root/archscript/chroot.sh
sed -i "s@GRUB_BOOTLOADER_ID=@GRUB_BOOTLOADER_ID=${GRUB_BOOTLOADER_ID}@g" /root/archscript/chroot.sh
sed -i "s@USERNAME=@USERNAME=${USERNAME}@g" /root/archscript/chroot.sh
cp /root/archscript/chroot.sh /mnt/chroot.sh
arch-chroot /mnt ./chroot.sh