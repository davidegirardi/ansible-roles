#!/bin/bash

set -o errexit

# Config
INSTALL_DISK="/dev/vda"
DISK_LABEL_TYPE="msdos"
ROOT_PART="${INSTALL_DISK}1"
ROOT_SIZE="100%"
CUSTOM_PACKAGES="bash-completion grub networkmanager openssh python sudo vim"

# Chroot config
export TIMEZONE="Europe/Stockholm"
export LOCALE="en_US.UTF-8"
export LOCALE_GEN="$LOCALE UTF-8"
export CONSOLE_KEYMAP="us"
export INSTALL_HOSTNAME="arch"
export INSTALL_DISK="$INSTALL_DISK"
export ROOT_PASSWORD="password"

# Commands defaults
PARTED="parted --script --align optimal"

function log() {
    echo -en '\E[1;33m'
    echo "[*] $*"
    tput sgr0
}
export -f log

log "Umount target filesystems (if any)"
umount -R /mnt || true

log Set keyboard layout $CONSOLE_KEYMAP
loadkeys $CONSOLE_KEYMAP

log Enable ntp
timedatectl set-ntp true

log Disk setup
log Create disk label
$PARTED $INSTALL_DISK mklabel $DISK_LABEL_TYPE
log Create Root partition $ROOT_PART
$PARTED $INSTALL_DISK mkpart primary ext4 0% 100%
mkfs.ext4 -L Root -m 1 $ROOT_PART

log Mount filesystems
mount $ROOT_PART /mnt
mkdir /mnt/boot

log pacstrap
pacstrap /mnt base linux linux-firmware $CUSTOM_PACKAGES

log generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

log Enter chroot
cp arch_chroot.sh /mnt
arch-chroot /mnt bash /arch_chroot.sh
rm /mnt/arch_chroot.sh
reboot
