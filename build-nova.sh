#!/bin/bash

# CM10 Kernel Compiler
# Date: 8/1/2012
# By Hei1125

##### Modify the parameters here #####
# Path of your toolchain
TOOLCHAIN=/home/hei/toolchains/arm-eabi-4.4.3/bin/arm-eabi-;
# Enable CCACHE
export USE_CCACHE=1;
######################################

# Get Current Directory Path
reldir=`dirname $0`;
cd $reldir;
DIR=`pwd`;

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
DATE=$(date +%Y%m%d);

echo "${bldgrn}#############################  CM10 Kernel Compiler #######################${txtrst}";

# Select the device to build
CHOICE="0";
while [ "$CHOICE" != "1" -o "$CHOICE" != "2" ]
do	
	echo -e "";
	echo "${bldyel} Please select your device: ${txtrst}";
	echo "${txtbld}	1: Hikari${txtrst}";
	echo "${txtbld}	2: Nozomi${txtrst}";
	read -p "Please input your choice (number): " CHOICE;
	if [ "$CHOICE" == "1" ]; then
		DEVICE="hikari";
		break;
	elif [ "$CHOICE" == "2" ]; then
		DEVICE="nozomi";
		break;
	else
		continue;
	fi	
done

# Choose whether make a clean build
CHOICE="0";
while [ "$CHOICE" != "1" -o "$CHOICE" != "2" ]
do	
	echo -e "";
	echo "${bldyel} Clean intermediates and output files?${txtrst}";
	echo "${txtbld}	1: Yes${txtrst}";
	echo "${txtbld}	2: No${txtrst}";
	read -p "Please input your choice (number): " CHOICE;
	if [ "$CHOICE" == "1" ]; then
		CLEAN="clean";
		break;
	elif [ "$CHOICE" == "2" ]; then
		CLEAN="";
		break;
	else
		continue;
	fi	
done;

echo -e "";
read -p "${bldgrn} Enter the kernel version number: v${txtrst}" VERSION;
ZIP=NovaKernel-$DEVICE-$VERSION.zip;

# Clean Intermediates and Outputs
if [ "$CLEAN" == "clean" ]; then
	echo -e ""
	echo -e "${bldblu} Cleaning intermediates and output files ${txtrst}"
	make clean;
fi

# Get Startup Time
res1=$(date +%s.%N);

# Copy Kernel Configuration
echo -e "";
echo -e "${cya} Copying ${bldcya}${DEVICE}${txtrst}${cya} Kernel Configuration ${txtrst}";
cp arch/arm/configs/${DEVICE}_defconfig .config;
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN oldconfig;

# Compile Kernel
# 2> warn.log means exporting the warning to a file called warn.log
echo -e "";
echo -e "${bldblu} Compiling Kernel for ${DEVICE} ${txtrst}";
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN 2> warn.log;

# Change Kernel to .elf format
echo -e ""
echo -e "${bldblu} Generating kernel.elf ${txtrst}"
cp arch/arm/boot/zImage kernel-build/$DEVICE;
cd kernel-build/$DEVICE;
mv zImage 0;
python mkelf.py -o kernel.elf 0@0x40208000 1@0x41500000,ramdisk 2@0x20000,rpm

# Pack Kernel to flashable zip
echo -e "";
echo -e "${bldblu} Packing kernel to flashable zip ${txtrst}";
cd $DIR;
cp kernel-build/$DEVICE/kernel.elf zip-format;
rm -f kernel-build/$DEVICE/kernel.elf;
rm -f kernel-build/$DEVICE/0;
cd zip-format;
zip -r $ZIP ./META-INF kernel.elf;

# Upload Kernel to Goo.im
echo -e "";
echo -e "${bldblu} Uploading the zip to Goo.im server ${txtrst}";
rsync -v -e ssh /home/hei1125/nova/zip-format/$ZIP goo.im:~/public_html/$DEVICE/Nova_Kernel;

# Remove leftovers in zip-format folder
rm -f $DIR/zip-format/kernel.elf;
rm -f $DIR/zip-format/$ZIP;

# Finished & Get Elapsed Time
res2=$(date +%s.%N);
echo -e "";
echo "${bldgrn} Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}";
