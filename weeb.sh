#!/bin/bash
cd ..
export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r328903/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build started for branch $(git rev-parse --abbrev-ref HEAD) using Clang 7.0.2!" -d chat_id=$CHAT_ID
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Latest Commits:
$(git log --pretty=format:'%h : %s' -{1..5})" -d chat_id=$CHAT_ID
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

# START, END and DIFF variables to calculate rough total compilation time!

START=$(date +"%s")
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r328903/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"	| tee $LOGFILE
EXITCODE=$?
#	Failure
if [ $EXITCODE -ne 0 ]; then 
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Senpai, I hate to tell you but... git commit die!
Build took so much time to fail building for OxygenOS miserably!
Check log file <code>$LOGFILE</code>" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$LOGFILE" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendSticker \
	-d sticker="CAADBQADUBwAAsZRxhXTwSK4KP5DpwI" \
	-d chat_id=${CHAT_ID} >> /dev/null
exit 1;
fi




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
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r328903/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"	| tee $LOGFILE
EXITCODE=$?

#	Failure
if [ $EXITCODE -ne 0 ]; then 
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Senpai, I hate to tell you but... git commit die!
Build took so much time to fail building for Treble ROMs miserably!
Check log file <code>$LOGFILE</code>" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$LOGFILE" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendSticker \
	-d sticker="CAADBQADUBwAAsZRxhXTwSK4KP5DpwI" \
	-d chat_id=${CHAT_ID} >> /dev/null
exit 1;
fi

END=$(date +"%s")
DIFF=$((END - START))

#	Success
mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/


#ReZIP the Kernel
cd $(pwd)/anykernel
ZIPNAME="WeebKerneL-Treble_V1.11.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME

#	Time to push the Kernel ZIP
cd ..
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build Success Oniisama!
The build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds to compile successfully!!
Uploading Kernel zip file here now!! 
	~(^.^)~" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/anykernel/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendSticker \
	-d sticker="CAADBQAD_gYAAsZRxhXEFftdkpzKwAI" \
	-d chat_id=${CHAT_ID} >> /dev/null