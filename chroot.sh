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

# SETUP BTRFS AND ENCRYPTION

#sed -i 's/BINARIES=()/BINARIES=(btrfs)/g' /etc/mkinitcpio.conf
sed -i 's/MODULES=()/MODULES=(btrfs)/g' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT/#GRUB_CMDLINE_LINUX_DEFAULT/g' /etc/default/grub
DISK_UUID=$(blkid | grep ${DISK}2 | awk '{print $2}' | awk '{split($0, a, "="); print a[2]}' | tr -d '"')
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=${DISK_UUID}:cryptroot root=/dev/mapper/cryptroot\"" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# SETUP ZRAM

pacman --noconfirm -S zram-generator
cat <<EOF >> /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
EOF

# SETUP USER

useradd -m -G wheel -s /bin/bash $USERNAME
passwd $USERNAME
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers