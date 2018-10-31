#!/bin/bash
cd ..

#
#	Setup
#
cd gcc
export CROSS_COMPILE=$(pwd)/bin/aarch64-opt-linux-android-
cd ..
export ARCH=arm64

#
#	Kernel - OxygenOS
#

make O=out weeb_defconfig
START=$(date +"%s")
make O=out -j$(nproc --all)

#	AnyKernel - OxygenOS
mkdir anykernel/kernels
mkdir anykernel/kernels/oos
mkdir anykernel/ramdisk/modules
#	Moving Image to AnyKernel
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/oos/
#	Moving wlan module to AnyKernel
cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
#	Stripping the wlan module to reduce size and remove unncessary parts
$(pwd)/gcc/bin/aarch64-opt-linux-android-strip --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
#	Signing the wlan module
find $(pwd)/anykernel/ramdisk/modules -name '*.ko' -exec $(pwd)/out/scripts/sign-file sha512 $(pwd)/out/certs/signing_key.pem $(pwd)/out/certs/signing_key.x509 {} \;

#
#	Prepare for next image
#

#
#	Kernel - Custom Treble ROMs
#

make O=out ARCH=arm64 weebcustom_defconfig
make O=out -j$(nproc --all)
END=$(date +"%s")
DIFF=$((END - START))

#	AnyKernel - Custom Treble ROMs

mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/

#	Prepare to make Flashable ZIP File
cd $(pwd)/anykernel
#	We are building for Treble ROMs, so there is no need for Non Treble anykernel.sh
rm -rf nontreble.sh
mv treble.sh anykernel.sh

#	Re-ZIP File
ZIPNAME="WeebKernel-Treble_GCC8_$(date '+%Y-%m-%d_%H:%M:%S').zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
#	Push to Telegram CI Channel
cd ..
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build Completed!
Time of compilation:$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.
Uploading GCC8 Kernel zip file here now" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/anykernel/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument