#!/bin/bash

set -o errexit

log Set time zone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

log Set the hwclock
hwclock --systohc

log Set the locale
echo "LANG=$LOCALE" > /etc/locale.conf
echo "$LOCALE_GEN" /etc/locale.gen
locale-gen

log Set the console keymap
echo "KEYMAP=$CONSOLE_KEYMAP" > /etc/vconsole.conf

log Set the hostname
echo $INSTALL_HOSTNAME > /etc/hostname

log Generate the hosts file
cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $INSTALL_HOSTNAME
EOF

log Install bootloader
grub-install --target=i386-pc $INSTALL_DISK
grub-mkconfig -o /boot/grub/grub.cfg

log "Configure bootloader (no secure boot and no microcode)"
mkdir -p /boot/loader/entries
cat << EOF > /boot/loader/loader.conf
default arch
timeout 1
editor 0
EOF

log Configure mkinitcpio
mkinitcpio -p linux

log Configure NetworkManager
systemctl enable NetworkManager
nmcli connection add autoconnect yes type ethernet con-name "Wired Connection" || true
echo 'nmcli connection add autoconnect yes type ethernet con-name "Wired Connection"' > /root/enable_network.sh

log Enable ssh server
systemctl enable sshd

log Set the root password
printf "$ROOT_PASSWORD\n%.0s" {1..2} | passwd

log Add user
useradd -d /home/user -m -G wheel -s /bin/bash user
printf "$ROOT_PASSWORD\n%.0s" {1..2} | passwd user

log Password-less sudo access for user
echo "user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/user && chmod 0440 /etc/sudoers.d/user
