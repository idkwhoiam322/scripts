#!/bin/bash
cd ..
# PREPPING

# Set Kernel Info
export VERA="-Hentai-o-W-o"
export VERB_SET=$(git rev-parse HEAD)
export VERB="$(date +%Y%m%d)-$(echo ${VERB_SET:0:4})"
VERSION="${VERA}-${VERB}-r${SEMAPHORE_BUILD_NUMBER}"

# Export User and Host
export KBUILD_BUILD_USER=idkwhoiam322
export KBUILD_BUILD_HOST=raphielgangci

# Release type
if [[ "$@" =~ "beta"* ]]; then
	export KERNEL_BUILD_TYPE="beta"
elif [[ "$@" =~ "stable"* ]]; then
	export VERA="Weeb-Kernel"
	export KERNEL_BUILD_TYPE="Stable"
	export VERSION="${VERA}-v${RELEASE_VERSION}-${RELEASE_CODENAME}"
fi

# Export versions
export KBUILD_BUILD_VERSION=204
export LOCALVERSION=`echo -${VERSION}`

# Set COMPILER
if [[ "$@" =~ "gcc" ]]; then
	export COMPILER=GCC
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-elf-"
	export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-eabi-"	
else
	export COMPILER=CLANG
	export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r370808/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
fi
export ARCH=arm64 && export SUBARCH=arm64

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi

if [[ "$@" =~ "stable"* ]]; then 
	export ZIPNAME="${VERSION}.zip"
else
	export ZIPNAME="${KERNEL_BUILD_TYPE}-r${SEMAPHORE_BUILD_NUMBER}-$(git rev-parse --abbrev-ref HEAD).$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')$(grep "EXTRAVERSION =" < Makefile | awk '{print $3}').zip"
fi

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then 
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>${KERNEL_BUILD_TYPE^^}</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Build Number: <code>r${SEMAPHORE_BUILD_NUMBER}</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on semaphore_ci....</i>" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build started for revision ${SEMAPHORE_BUILD_NUMBER}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
fi


# compilation
START=$(date +"%s")
make O=out ARCH=arm64 $DEFCONFIG
if [[ "$@" =~ "gcc" ]]; then
	make -j${KEBABS} O=out ARCH=arm64
else
	make -j${KEBABS} O=out ARCH=arm64 CC="/home/runner/${SEMAPHORE_PROJECT_NAME}/clang/clang-r370808/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc32/bin/arm-linux-androideabi-"
fi
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip for custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel

# POST ZIP OR FAILURE
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds!" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi
rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb && rm -rf modules
cd ..
