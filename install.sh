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
# add pacman color and parallel downloads option
# check timedatectl status is synchronized
pacman -Syy

# SETUP DISK AND FILE SYSTEM

# partition disk and encryption
mkfs.vfat -n BOOT ${DISK}1
mkfs.btrfs -n ROOT ${DISK}2
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
arch-chroot /mnt

# BASE SYSTEM CONFIGURATION

ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
hwclock --systohc --utc
reflector --country $MIRRORLIST_COUNTRY --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
# add pacman color and parallel downloads option
pacman -Syy
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
echo $HOSTNAME > /etc/hostname
cat <<EOF >> /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
pacman --noconfirm -S ${CPU_BRAND}-ucode
pacman --noconfirm -S os-prober efiboot-mgr grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${GRUB_BOOTLOADER_ID}
grub-mkconfig -o /boot/grub/grub.cfg
sed -i 's/BINARIES=()/BINARIES=(btrfs)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
systemctl enable --now reflector.timer

# SETUP DESKTOP ENVIRONMENT

# install desktop environment and related stuff

# SETUP USER

# setup user

# INSTALL PARU

git clone https:///aur.archlinux.org/paru
cd paru
makepkg -si --noconfirm
cd ..
rm -rf paru

# SETUP SNAPPER

paru --noconfirm -S grub-btrfs snap-pac snapper snapper-support
snapper -c root create-config /
# check if using systemd timers
# add creation and fixing btrfs subvolumes
sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"/g' /etc/snapper/configs/root
sed -i 's/TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/g' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/g' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"/g' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="0"/g' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/g' /etc/snapper/configs/root
chown -R :wheel /.snapshots
snapper -c root create -d "BASE"

# SETUP ZRAM

paru --noconfirm -S zram-generator
cat <<EOF >> /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
EOF
systemctl daemon-reload
systemctl start /dev/zram0

# ---

exit
umount -a
reboot
# other usually post-install stuff
# cups
