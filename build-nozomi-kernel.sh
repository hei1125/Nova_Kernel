#!/bin/bash

# CM10 Nozomi (Sony Xperia S) Kernel Compiler
# Date: 22/12/2012
# By Hei1125

##### Variables #####
# Path of your Kernel Directory
kernel_dir=/home/hei/android/NOVA-Kernel;
# Path of your toolchain
toolchain=/home/hei/android/toolchains/arm-eabi-4.4.3/bin/arm-eabi-;
# Path of Shared folder of the virtual box
sharedfolder=/media/sf_Desktop;
# Name of flashable zip
flashable_zip=NovaKernel-Nozomi-exp.zip;

# Enable ccache
export USE_CCACHE=1;

# Go to Kernel Folder
cd $kernel_dir;

# Kernel Configuration
cp arch/arm/configs/nozomi_defconfig .config;
make ARCH=arm CROSS_COMPILE=$toolchain oldconfig;

# Compile Kernel
# 2> warn.log means exporting the warning to a file called warn.log
make ARCH=arm CROSS_COMPILE=$toolchain -j8 2> warn.log;

# Change Kernel to elf format
cp arch/arm/boot/zImage kernel-build/nozomi;
cd kernel-build/nozomi;
mv zImage 0;
python mkelf.py -o kernel.elf 0@0x40208000 1@0x41500000,ramdisk 2@0x20000,rpm

# Pack Kernel to flashable zip
cd $kernel_dir;
cp kernel-build/nozomi/kernel.elf zip-format;
rm -f kernel-build/nozomi/kernel.elf;
rm -f kernel-build/nozomi/0;
cd zip-format;
zip -r $flashable_zip ./META-INF kernel.elf;

# Move Kernel to shared folder
cp $flashable_zip $sharedfolder;

# Remove leftovers in zip-format folder
rm -f $kernel_dir/zip-format/kernel.elf;
rm -f $kernel_dir/zip-format/$flashable_zip;

