# Archscript

A script to automate the installation of Arch Linux

### **!!! Work in Progress !!!**

## Why?

Obviously to avoid doing things manually everytime, and because I wanted something simpler and more specific than the archinstall tool.

## Features and Limitations

The script will setup Arch Linux with the following configuration and is intended to be used with a single ssd:
- UEFI
- rank pacman mirror list by country with reflector
- partition disk and setup ssd friendly mount options
- format with btrfs and snapper for snapshots
- zram
- paru and flatpak
- gnome

**This script is highly experimental and specific and it doesn't do any checks on user inputs and possible errors**

## Usage

The script needs to be executed inside the live usb with network connectivity already working:
- ```
  pacman -Syy
  pacman -S git
  git clone https://github.com/ciori/archscript.git
  cd archscript
  chmod +x install.sh
  ```
- populate variables inside install.sh: `vim install.sh`
- execute the script: `./install.sh`
  - it will finish by opening the sudoers file with visudo, uncomment the wheel line to allow the user to use sudo
- reboot the system and login with the created user
- execute the post reboot script: `curl -sSL https://raw.githubusercontent.com/ciori/archscript/main/post-reboot.sh | bash`

## TODOs

Some things not yet implemented:
- secure boot support
- disk encryption
- Discard/TRIM option in cryptdevice?