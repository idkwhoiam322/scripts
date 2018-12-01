#!/bin/bash
cd ..

export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r346389/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
rm -rf out
mkdir -p out

#	Let's compile this mess
#
#	Time for OxygenOS Treble
#
make O=out ARCH=arm64 weeb_defconfig
chmod +x -R $(pwd)/

#
#	Compile the Kernel
#

make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r346389/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"

#	Success
rm -rf $(pwd)/anykernel/ramdisk/modules/wlan.ko
rm -rf $(pwd)/anykernel/kernels/oos/Image.gz-dtb
chmod +x -R $(pwd)/out

#	Preparing Kernel ZIP
mkdir anykernel/kernels
mkdir anykernel/kernels/oos
mkdir anykernel/ramdisk/modules
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/oos/
cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
$(pwd)/gcc/bin/aarch64-linux-android-strip --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
find $(pwd)/anykernel/ramdisk/modules -name '*.ko' -exec $(pwd)/out/scripts/sign-file sha512 $(pwd)/out/certs/signing_key.pem $(pwd)/out/certs/signing_key.x509 {} \;

#
#	Time for Custom Treble
#

rm -rf out
mkdir -p out
make O=out ARCH=arm64 weebcustom_defconfig
chmod +x -R $(pwd)/
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r346389/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"

#	Success
mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/


#	ReZIP the Kernel
cd $(pwd)/anykernel
rm -rf nontreble.sh
mv treble.sh anykernel.sh
ZIPNAME="WeebKerneL-Treble_V1.13.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME

#	Time to push the Kernel ZIP
cd ..
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/anykernel/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument