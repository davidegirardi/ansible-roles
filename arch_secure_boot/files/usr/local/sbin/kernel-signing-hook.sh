#!/bin/bash

function packageAndSign()
{
    KERNEL_FILE=$(basename "$1")
    FILE_NAME=${KERNEL_FILE#vmlinuz-}
    BOOTDIR="/boot"
    CERTDIR="/etc/secureboot"
    KERNEL="$1"
    INITRAMFS="$(ls /boot/*-ucode.img)"
    INITRAMFS="$INITRAMFS /boot/initramfs-$FILE_NAME.img"
    EFISTUB="/usr/lib/systemd/boot/efi/linuxx64.efi.stub"
    BUILDDIR="$(mktemp -d)"
    OUTIMG="/boot/$FILE_NAME-signed.img"
    CMDLINE="/etc/secureboot/kernel-cmdline-$FILE_NAME.conf"
    if [ ! -f "$CMDLINE" ]
    then
        CMDLINE="/proc/cmdline"
    fi
    OS_RELEASE="/usr/lib/os-release"
    DB_KEY="${CERTDIR}/db.key"
    DB_CRT="${CERTDIR}/db.crt"

    mkdir -p $BUILDDIR
    chmod 700 $BUILDDIR

    echo "==> Working on $1"
    echo "==> Using the command line from $CMDLINE"
    echo "==> Creating signed boot image for $KERNEL_FILE in $BUILDDIR"

    echo "  -> Preparing the initramfss ($INITRAMFS)"
    cat ${INITRAMFS} > ${BUILDDIR}/initramfs.img

    echo "  -> Preparing the EFI image..."
    /usr/bin/objcopy \
        --add-section .osrel=${OS_RELEASE} --change-section-vma .osrel=0x20000 \
        --add-section .cmdline=${CMDLINE} --change-section-vma .cmdline=0x30000 \
        --add-section .linux=${KERNEL} --change-section-vma .linux=0x40000 \
        --add-section .initrd=${BUILDDIR}/initramfs.img --change-section-vma .initrd=0x3000000 \
        ${EFISTUB} ${BUILDDIR}/combined-boot.efi

    echo "  -> Signing the EFI image..."
    /usr/bin/sbsign --key ${DB_KEY} --cert ${DB_CRT} --output ${BUILDDIR}/combined-boot-signed.efi ${BUILDDIR}/combined-boot.efi

    echo "  -> Copying the signed EFI image from ${BUILDDIR}/combined-boot-signed.efi to ${OUTIMG} ..."
    cp ${BUILDDIR}/combined-boot-signed.efi ${OUTIMG}

    echo "  -> Cleanup of ${BUILDDIR} ..."
    rm -r "$BUILDDIR"
}

packageAndSign "$1"

