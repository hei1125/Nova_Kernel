#!/bin/bash

# CM10 Fuji Kernel Compiler
# Date: 27/12/2012
# By Hei1125

##### Modify the path here #####
# Path of your toolchain
TOOLCHAIN=/home/hei/android/toolchains/arm-eabi-4.4.3/bin/arm-eabi-;
# Path of Shared folder of the virtual box
SHARED=/media/sf_Desktop;
# Number of Threads
THREADS="8"
# Name of flashable zip
ZIP=NovaKernel-$DEVICE-exp-$date.zip;
# Ccache
export USE_CCACHE=1;
################################

# Colorize and add text parameters
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldyel=${txtbld}$(tput setaf 3) #  yellow
bldblu=${txtbld}$(tput setaf 4) #  blue
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             # Reset

# Parameters
DEVICE="$1";
CLEAN="$2";
CHOICE="0";
while [ "$CHOICE" != "1" -o "$CHOICE" != "2" ]
do
	if [ "$DEVICE" != "hikari" -a "$DEVICE" != "nozomi" ]; then
		if [ "$DEVICE" == "clean" ]; then
			CLEAN="$1";
		fi
		echo "${bldyel}Please select your device:${txtrst}"
		echo "${txtbld}	1: Hikari${txtrst}"
		echo "${txtbld}	2: Nozomi${txtrst}"
		read -p "" CHOICE
		if [ "$CHOICE" == "1" ]; then
			DEVICE="hikari";
			break;
		elif [ "$CHOICE" == "2" ]; then
			DEVICE="nozomi";
			break;
		fi
	fi
	break;
done
if [ "$CLEAN" == "clean" ]; then
	echo -e ""
	echo -e "${bldblu}Cleaning intermediates and output files ${txtrst}"
	make clean;
fi
# Get Startup Time
res1=$(date +%s.%N)

# Get Current Directory Path
reldir=`dirname $0`;
cd $reldir;
DIR=`pwd`;

# Date
date=$(date +%Y%m%d);

# Copy Kernel Configuration
echo -e "";
echo -e "${cya}Copying ${bldcya}${DEVICE} ${txtrst}${cya}Kernel Configuration ${txtrst}";
cp arch/arm/configs/${DEVICE}_defconfig .config;
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN oldconfig;

# Compile Kernel
# 2> warn.log means exporting the warning to a file called warn.log
echo -e "";
echo -e "${bldblu}Compiling Kernel ${txtrst}";
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN -j8 2> warn.log;

# Change Kernel to elf format
echo -e ""
echo -e "${bldblu}Generating kernel.elf ${txtrst}"
cp arch/arm/boot/zImage kernel-build/$DEVICE;
cd kernel-build/$DEVICE;
mv zImage 0;
python mkelf.py -o kernel.elf 0@0x40208000 1@0x41500000,ramdisk 2@0x20000,rpm

# Pack Kernel to flashable zip
echo -e "";
echo -e "${bldblu}Packing kernel to flashable zip ${txtrst}";
cd $DIR;
cp kernel-build/$DEVICE/kernel.elf zip-format;
rm -f kernel-build/$DEVICE/kernel.elf;
rm -f kernel-build/$DEVICE/0;
cd zip-format;
zip -r $ZIP ./META-INF kernel.elf;

# Move Kernel to shared folder
cp $ZIP $SHARED;

# Remove leftovers in zip-format folder
rm -f $DIR/zip-format/kernel.elf;
rm -f $DIR/zip-format/$ZIP;

# Finished & Get Elapsed Time
res2=$(date +%s.%N);
echo -e "";
echo "${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"

