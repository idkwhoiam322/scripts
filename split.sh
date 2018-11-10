#!/bin/bash
cd ..

export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r344140/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build started for branch $(git rev-parse --abbrev-ref HEAD) using Clang 8.0.3!
Latest Commits:
$(git log --pretty=format:'%h : %s' -{1..5})" -d chat_id=$CHAT_ID
#	Let's compile this mess
#
#	Time for OxygenOS Treble
#
make O=out ARCH=arm64 weeb_defconfig

#
#	Compile the Kernel for OxygenOS
#

#	START, END and DIFF variables to calculate rough total compilation time!

START=$(date +"%s")
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r344140/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"
END=$(date +"%s")
DIFF=$((END - START))

#	Success
#	Remove any residue
rm -rf $(pwd)/anykernel/ramdisk/modules/wlan.ko
rm -rf $(pwd)/anykernel/kernels/oos/Image.gz-dtb

#	Preparing Kernel ZIP
mkdir anykernel/kernels
mkdir anykernel/kernels/oos
mkdir anykernel/ramdisk/modules
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/oos/
cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
$(pwd)/gcc/bin/aarch64-linux-android-strip --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
find $(pwd)/anykernel/ramdisk/modules -name '*.ko' -exec $(pwd)/out/scripts/sign-file sha512 $(pwd)/out/certs/signing_key.pem $(pwd)/out/certs/signing_key.x509 {} \;


cd $(pwd)/anykernel
#	We don't ned non treble anykernel
rm -rf nontreble.sh
mv treble.sh anykernel.sh

#	Name and push zip
ZIPNAME="WEEB_KERNEL_OOSr$SEMAPHORE_BUILD_NUMBER.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Kernel: Weeb Kernel
Type: BETA
Revision: $REVISION
ROM Support: OxygenOS
Compilation Time: $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds
Uploading...." -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
rm -rf $ZIPNAME
rm -rf kernels/oos
rm -rf ramdisk/modules
cd ..



#
#	Time for Custom Treble
#
make O=out ARCH=arm64 weebcustom_defconfig
START=$(date +"%s")
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r344140/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"
END=$(date +"%s")
DIFF=$((END - START))

#	Success
mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/

#	Name and push zip
cd $(pwd)/anykernel
ZIPNAME="WEEB_KERNEL_TREBLEr$SEMAPHORE_BUILD_NUMBER.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME

#	Time to push the Custom ROM Treble Kernel ZIP
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Kernel: Weeb Kernel
Type: BETA
Revision: $REVISION
ROM Support: Custom Treble ROMs
Compilation Time: $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds
Uploading...." -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
# Extra line here for OCD

# Oh there were 2 lines
# Oh 3
# Ok I'll stop here