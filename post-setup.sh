#!/bin/bash

# INSTALL PARU

git clone https://aur.archlinux.org/paru
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

# ---

# other usually post-install stuff

# FLATPAK

# ...