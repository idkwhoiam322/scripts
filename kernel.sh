#!/bin/bash
cd ..
export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r328903/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";

curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build started for branch $(git rev-parse --abbrev-ref HEAD) using Clang 7.0.2!" -d chat_id=$CHAT_ID
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Latest Commits:
$(git log --pretty=format:'%h : %s' -{1..5})" -d chat_id=$CHAT_ID
rm -rf out
mkdir -p out
make O=out ARCH=arm64 test_defconfig
chmod +x -R $(pwd)/
ZIPNAME="WeebKernelOOS_$(date '+%Y-%m-%d_%H:%M:%S').zip"
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r328903/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"	| tee $LOGFILE

#Failure
EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then 
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build Failed! Check log file <code>$LOGFILE</code>" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$LOGFILE" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
exit 1;
fi

#Success
rm -rf $(pwd)/anykernel/ramdisk/modules/wlan.ko
rm -rf $(pwd)/anykernel/kernels/oos/Image.gz-dtb
chmod +x -R $(pwd)/out
mkdir anykernel/kernels
mkdir anykernel/kernels/oos
mkdir anykernel/ramdisk/modules
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/oos/
cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
$(pwd)/gcc/bin/aarch64-linux-android-strip --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
find $(pwd)/anykernel/ramdisk/modules -name '*.ko' -exec $(pwd)/out/scripts/sign-file sha512 $(pwd)/out/certs/signing_key.pem $(pwd)/out/certs/signing_key.x509 {} \;
cd $(pwd)/anykernel
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
cd ..
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Download:" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/anykernel/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
