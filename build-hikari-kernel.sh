#!/bin/bash

# CM10 Hikari Kernel Compiler
# Date: 16/12/2012
# By Hei1125

# Variables
working_dir=/home/hei/android;
kernel_dir=/home/hei/android/NOVA-Kernel;
toolchain=/home/hei/android/toolchains/arm-eabi-4.4.3/bin/arm-eabi-;

# Enable ccache
export USE_CCACHE=1;

# Go to Kernel Folder
cd $kernel_dir;

# Config Hikari (Sony Xperia Acro S) Non-OC Kernel
cp arch/arm/configs/hikari_defconfig .config;
make ARCH=arm CROSS_COMPILE=$toolchain oldconfig;

# Build Kernel
make ARCH=arm CROSS_COMPILE=$toolchain -j`grep 'processor' /proc/cpuinfo | wc -l` 2> warn.log;

# Change to elf format
cp arch/arm/boot/zImage kernel-build/hikari;
cd kernel-build/hikari;
mv zImage 0;
python mkelf.py -o kernel.elf 0@0x40208000 1@0x41500000,ramdisk 2@0x20000,rpm

# Pack Kernel to flashable zip
cd $kernel_dir;
cp kernel-build/hikari/kernel.elf zip-format;
rm -f kernel-build/hikari/kernel.elf;
rm -f kernel-build/hikari/0;
cd zip-format;
zip -r NovaKernel-Hikari-Non-OC.zip ./META-INF kernel.elf;

# Move Kernel to shared folder
cp NovaKernel-Hikari-Non-OC.zip /media/sf_Desktop;

# Remove leftovers in zip-format folder
rm -f $kernel_dir/zip-format/kernel.elf;
rm -f $kernel_dir/zip-format/NovaKernel-Hikari-Non-OC.zip;

