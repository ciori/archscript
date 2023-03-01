#!/bin/bash

MIRRORLIST_COUNTRY=
DISK=
TIME_ZONE=
HOSTNAME=
CPU_BRAND=
GRUB_BOOTLOADER_ID=
USERNAME=

# BASE SYSTEM CONFIGURATION

ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
hwclock --systohc --utc
reflector --country $MIRRORLIST_COUNTRY --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
systemctl enable --now reflector.timer
sed -i 's/#Color/Color/g' /etc/pacman.conf
sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf
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
pacman --noconfirm -S os-prober efibootmgr grub
pacman --noconfirm -S btrfs-progs
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${GRUB_BOOTLOADER_ID}
grub-mkconfig -o /boot/grub/grub.cfg

# SETUP BTRFS

sed -i 's/BINARIES=()/BINARIES=(btrfs)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

# SETUP DESKTOP ENVIRONMENT

pacman --noconfirm -S pipewire pipewire-jack wireplumber
pacman --noconfirm -S gnome

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
