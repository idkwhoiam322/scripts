#!/bin/bash
cd ..
rm -rf out
# PREPPING

# Set Kernel Info
export VERA="Hentai"
export VERB_SET=$(git rev-parse HEAD)
VERSION="${VERA}-personal-r${SEMAPHORE_BUILD_NUMBER}-${VERB_SET:0:7}"

# Export User and Host
export KBUILD_BUILD_USER=idkwhoiam322
export KBUILD_BUILD_HOST=raphielgangci

# Save current HEAD
export ACTUAL_HEAD=$(git rev-parse HEAD)

# set git config details
git config user.email "idkwhoiam322@raphielgang.org"
git config user.name "idkwhoiam322"
# apply patches
cd pp
git am -3 *.patch
cd ..

# Release type
if [[ "$@" =~ "beta"* ]]; then
	export KERNEL_BUILD_TYPE="beta"
else
	exit 0;
fi

# Export versions
export KBUILD_BUILD_VERSION=204
export LOCALVERSION=`echo ${VERSION}`

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


export ZIPNAME="personal-r${SEMAPHORE_BUILD_NUMBER}-$(git rev-parse --abbrev-ref HEAD).$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')$(grep "EXTRAVERSION =" < Makefile | awk '{print $3}').zip"

# compilation
make O=out ARCH=arm64 $DEFCONFIG
if [[ "$@" =~ "gcc" ]]; then
	make -j${KEBABS} O=out ARCH=arm64
else
	make -j${KEBABS} O=out ARCH=arm64 CC="/home/runner/${SEMAPHORE_PROJECT_NAME}/clang/clang-r370808/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc32/bin/arm-linux-androideabi-"
fi

# prepare zip for custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel


# POST ZIP OR FAILURE
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build r${SEMAPHORE_BUILD_NUMBER} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi
rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb && rm -rf modules
cd ..

# Reset back to actual head for user builds
git reset --hard ${ACTUAL_HEAD}
