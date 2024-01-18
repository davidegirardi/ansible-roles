#!/bin/bash

set -o errexit

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

    echo "  -> Preparing the initramfs ($INITRAMFS)"
    cat ${INITRAMFS} > ${BUILDDIR}/initramfs.img

    echo "  -> Preparing the EFI image..."
    # From: https://wiki.debian.org/EFIStub
    align="$(objdump -p ${EFISTUB} | awk '{ if ($1 == "SectionAlignment"){print $2} }')"
    align=$((16#$align))
    osrel_offs="$(objdump -h ${EFISTUB} | awk 'NF==7 {size=strtonum("0x"$3); offset=strtonum("0x"$4)} END {print size + offset}')"
    osrel_offs=$((osrel_offs + "$align" - osrel_offs % "$align"))
    cmdline_offs=$((osrel_offs + $(stat -Lc%s ${OS_RELEASE})))
    cmdline_offs=$((cmdline_offs + "$align" - cmdline_offs % "$align"))
    splash_offs=$((cmdline_offs + $(stat -Lc%s ${CMDLINE})))
    splash_offs=$((splash_offs + "$align" - splash_offs % "$align"))
    #initrd_offs=$((splash_offs + $(stat -Lc%s "/path/to/splash.bmp")))
    initrd_offs=${splash_offs}
    initrd_offs=$((initrd_offs + "$align" - initrd_offs % "$align"))
    linux_offs=$((initrd_offs + $(stat -Lc%s ${BUILDDIR}/initramfs.img)))
    linux_offs=$((linux_offs + "$align" - linux_offs % "$align"))

    # Original from Debian
    # /usr/bin/objcopy \
    #     --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=$(printf 0x%x $osrel_offs) \
    #     --add-section .cmdline="/path/to/cmdline" --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    #     --add-section .splash="/path/to/splash.bmp" --change-section-vma .splash=$(printf 0x%x $splash_offs) \
    #     --add-section .initrd="/path/to/initrd.img" --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    #     --add-section .linux="/path/to/vmlinuz" --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    #     "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "/boot/efi/EFI/Linux/debian.efi"

    /usr/bin/objcopy \
        --add-section .osrel=${OS_RELEASE} --change-section-vma .osrel=${osrel_offs} \
        --add-section .cmdline=${CMDLINE} --change-section-vma .cmdline=${cmdline_offs} \
        --add-section .initrd=${BUILDDIR}/initramfs.img --change-section-vma .initrd=${initrd_offs} \
        --add-section .linux=${KERNEL} --change-section-vma .linux=${linux_offs} \
        ${EFISTUB} ${BUILDDIR}/combined-boot.efi

    echo "  -> Signing the EFI image..."
    /usr/bin/sbsign --key ${DB_KEY} --cert ${DB_CRT} --output ${BUILDDIR}/combined-boot-signed.efi ${BUILDDIR}/combined-boot.efi

    echo "  -> Copying the signed EFI image from ${BUILDDIR}/combined-boot-signed.efi to ${OUTIMG} ..."
    cp ${BUILDDIR}/combined-boot-signed.efi ${OUTIMG}

    echo "  -> Cleanup of ${BUILDDIR} ..."
    rm -r "$BUILDDIR"
}

packageAndSign "$1"

