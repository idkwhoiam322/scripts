#!/bin/bash
cd ..

export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r344140/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>BETA</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>Clang 8.0.3</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
ROM Support: <code>Treble ROMs (Custom and OxygenOS)</code>
<i>Build started....</i>" -d chat_id=$CHAT_ID -d parse_mode=HTML
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

#	Success
#	Remove any residue
rm -rf $(pwd)/anykernel/ramdisk/modules/wlan.ko
rm -rf $(pwd)/anykernel/kernels/oos/Image.gz-dtb

#	Preparing Kernel ZIP for OxygenOS
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
cd ..

#
#	Time for Custom Treble
#
make O=out ARCH=arm64 weebcustom_defconfig
START=$(date +"%s")
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r344140/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"
END=$(date +"%s")
DIFF=$((END - START))

#	Preparing Kernel ZIP for Custom Treble ROMs
mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/

#	Name and push zip
cd $(pwd)/anykernel
ZIPNAME="WEEB_KERNEL_TREBLE_r$SEMAPHORE_BUILD_NUMBER.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
CHECKER=$(ls -l $ZIPNAME | awk '{print $5}')
if (($((CHECKER / 1048576)) > 5));
then
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build Version: <code>r$SEMAPHORE_BUILD_NUMBER</code>
	Compilation Time: <code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</code>
	<i>Uploading....</i>" -d chat_id=$CHAT_ID -d parse_mode=HTML
	curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="The compiler decides to scream at @idkwhoiam322" -d chat_id=$CHAT_ID	
fi;
# Extra line here for OCD

# Oh there were 2 lines
# Oh 3
# Ok I'll stop here