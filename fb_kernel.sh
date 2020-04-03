#!/bin/bash

export kitchen_tools=${HOME}/kernel/kitchen_tools

if [[ "$@" =~ "stock" ]]; then
	export stock=1
fi

# Ensure that we are ready to flash/boot!
if [[ ! "$@" =~ "skip"* ]] ; then
	adb shell reboot bootloader || { echo 'Phone is not connected!' ; exit 1; }
fi

export BOOT_IMG_NAME="A32_bk.img"

if [[ "$@" =~ "new"* ]] || [[ "$stock" == "1" ]] ; then
	bash ${kitchen_tools}/unpackimg.sh $BOOT_IMG_NAME || { echo '$BOOT_IMG_NAME not found!' ; exit 1; }
fi

if [[ "$@" =~ "skip"* ]]; then
	exit 1;
fi

if [[ "$stock" == "1" ]] ; then
	if [[ ! "$@" =~ "noroot"* ]]; then
		decomp_image=${kitchen_tools}/split_img/${BOOT_IMG_NAME}-zImage
		magiskboot=${kitchen_tools}/magiskboot

		chmod 777 $magiskboot
		# Reverse patch kernel image for magisk removal
		sudo $magiskboot hexpatch $decomp_image 77616E745F696E697472616D667300 736B69705F696E697472616D667300;
	fi
else
	# Weeb/Hentai switcheroo
		rm -rf  ${kitchen_tools}/kernel
		unzip ${kitchen_tools}/*.zip -d ${kitchen_tools}/kernel

		rm -rf ${kitchen_tools}/split_img/*zImage
		rm -rf ${kitchen_tools}/split_img/*dtb

	if [[ ! "$@" =~ "noroot"* ]]; then
		# Patch kernel image for magisk
		decomp_image=${kitchen_tools}/kernel/Image
		comp_image=$decomp_image.gz
		magiskboot=${kitchen_tools}/magiskboot

		chmod 777 $magiskboot
		sudo $magiskboot decompress $comp_image $decomp_image;
		sudo $magiskboot hexpatch $decomp_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
		sudo $magiskboot compress=gzip $decomp_image $comp_image;
	fi

	cp ${kitchen_tools}/kernel/Image.gz ${kitchen_tools}/split_img/${BOOT_IMG_NAME}-zImage
	cp ${kitchen_tools}/kernel/dtb ${kitchen_tools}/split_img/${BOOT_IMG_NAME}-dtb
fi

bash ${kitchen_tools}/repackimg.sh

if [[ "$@" =~ "flash"* ]]; then
	sudo fastboot --slot all flash boot ${kitchen_tools}/image-new.img
	sudo fastboot reboot
else
	sudo fastboot boot ${kitchen_tools}/image-new.img
fi
