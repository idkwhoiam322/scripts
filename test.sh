#!/bin/bash
cd ..
# PREPPING

# Set Kernel Info
export VERA="-weeb"
export VERB_SET=$(git rev-parse HEAD)
export VERB="$(date +%Y%m%d)-$(echo ${VERB_SET:0:4})"
VERSION="${VERA}-${VERB}"

# Export User and Host
export KBUILD_BUILD_USER=idkwhoiam322
export KBUILD_BUILD_HOST=Kebabs

# Export versions
export KBUILD_BUILD_VERSION=1
export LOCALVERSION=`echo ${VERSION}`

# Set COMPILER
if [[ "$@" =~ "gcc" ]]; then
	export COMPILER=GCC
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-gnu-"
	export STRIP="$(pwd)/gcc/bin/aarch64-linux-gnu-strip"
	
else
	export COMPILER=CLANG
	export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r346389c/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
	export STRIP=$(pwd)/gcc/bin/aarch64-linux-android-strip
	export CC="$(pwd)/clang/clang-r346389c/bin/clang"
	export CLANG_TRIPLE=aarch64-linux-gnu-
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"
fi
export ARCH=arm64 && export SUBARCH=arm64

curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>BETA</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on semaphore_ci....</i>" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build started for revision ${SEMAPHORE_BUILD_NUMBER}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML

export DEFCONFIG=weeb_defconfig
export BUILDFOR=oos
export ZIPNAME="weeb-${COMPILER,,}-${BUILDFOR}-r${SEMAPHORE_BUILD_NUMBER}-${VERB}.zip"
make O=out ARCH=arm64 $DEFCONFIG
START=$(date +"%s")
make O=out -j16
END=$(date +"%s")
DIFF=$((END - START))
mkdir anykernel/modules
mkdir anykernel/modules/vendor
mkdir anykernel/modules/vendor/lib
mkdir anykernel/modules/vendor/lib/modules
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/modules/vendor/lib/modules
mv $(pwd)/anykernel/modules/vendor/lib/modules/wlan.ko $(pwd)/anykernel/modules/vendor/lib/modules/qca_cld3_wlan.ko
${STRIP} --strip-unneeded $(pwd)/anykernel/modules/vendor/lib/modules/qca_cld3_wlan.ko
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')
if (($((CHECKER / 1048576)) < 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${BUILDFOR}" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
rm -rf ${ZIPNAME} && rm -rf modules && rm -rf Image.gz-dtb
ls
cd ..


export DEFCONFIG=weebcustom_defconfig
export BUILDFOR=custom
export ZIPNAME="weeb-${COMPILER,,}-${BUILDFOR}-r${SEMAPHORE_BUILD_NUMBER}-${VERB}.zip"
make O=out ARCH=arm64 $DEFCONFIG
START=$(date +"%s")
make O=out -j16
END=$(date +"%s")
DIFF=$((END - START))
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
if (($((CHECKER / 1048576)) < 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${BUILDFOR}" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb
ls
cd ..


export DEFCONFIG=weebomni_defconfig
export BUILDFOR=omni
export ZIPNAME="weeb-${COMPILER,,}-${BUILDFOR}-r${SEMAPHORE_BUILD_NUMBER}-${VERB}.zip"
make O=out ARCH=arm64 $DEFCONFIG
START=$(date +"%s")
make O=out -j16
END=$(date +"%s")
DIFF=$((END - START))
mkdir anykernel/modules
mkdir anykernel/modules/system
mkdir anykernel/modules/system/lib
mkdir anykernel/modules/system/lib/modules
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/modules/system/lib/modules
${STRIP} --strip-unneeded $(pwd)/anykernel/modules/system/lib/modules/wlan.ko
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
if (($((CHECKER / 1048576)) < 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${BUILDFOR}" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
rm -rf ${ZIPNAME} && rm -rf modules && rm -rf Image.gz-dtb
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="All three builds have been posted in the CI channel!" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
rm -rf ${ZIPNAME} && rm -rf modules && rm -rf Image.gz-dtb
ls
cd ..