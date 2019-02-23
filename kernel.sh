#!/bin/bash
cd ..
# PREPPING

# Set Kernel Info
export VERA="-Hentai"
export VERB_SET=$(git rev-parse HEAD)
export VERB="$(date +%Y%m%d)-$(echo ${VERB_SET:0:4})"
VERSION="${VERA}-${VERB}-r${SEMAPHORE_BUILD_NUMBER}"

# Export User and Host
export KBUILD_BUILD_USER=idkwhoiam322
export KBUILD_BUILD_HOST=RaphielGang

# Release type
if	[[ "$@" =~ "alpha"* ]]; then
	export KERNEL_BUILD_TYPE="alpha"
elif [[ "$@" =~ "beta"* ]]; then
	export KERNEL_BUILD_TYPE="beta"
elif [[ "$@" =~ "stable"* ]]; then
	export VERA="-Weeb-Kernel"
	export KERNEL_BUILD_TYPE="Stable"
	export RELEASE_VERSION="2.10"
	export RELEASE_CODENAME="AURA"
	export VERSION="${VERA}-${KERNEL_BUILD_TYPE}-v${RELEASE_VERSION}-${RELEASE_CODENAME}"
fi

# Export versions
export KBUILD_BUILD_VERSION=1
export LOCALVERSION=`echo ${VERSION}`

# Set COMPILER
if [[ "$@" =~ "gcc" ]]; then
	export COMPILER=GCC
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-gnu-"
	export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-gnueabi-"
	export STRIP="$(pwd)/gcc/bin/aarch64-linux-gnu-strip"
	
else
	export COMPILER=CLANG
	export STRIP=$(pwd)/gcc/bin/aarch64-linux-android-strip
fi
export ARCH=arm64 && export SUBARCH=arm64

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi


if [[ "$@" =~ "oos"* ]]; then 
	export DEFCONFIG=weeb_defconfig
	export BUILDFOR=oos
fi

if [[ "$@" =~ "custom"* ]]; then
	export DEFCONFIG=weebcustom_defconfig
	export BUILDFOR=custom
fi

if [[ "$@" =~ "stable"* ]]; then 
	export ZIPNAME="${BUILDFOR}${VERSION}.zip"
else
	export ZIPNAME="${KERNEL_BUILD_TYPE}-r${SEMAPHORE_BUILD_NUMBER}-${BUILDFOR}-$(git rev-parse --abbrev-ref HEAD)-$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')$(grep "EXTRAVERSION =" < Makefile | awk '{print $3}').zip"
fi

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then 
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>${KERNEL_BUILD_TYPE^^}</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on semaphore_ci....</i>" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build started for revision ${SEMAPHORE_BUILD_NUMBER}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
fi


# compilation
START=$(date +"%s")
make O=out ARCH=arm64 $DEFCONFIG
if [[ "$@" =~ "gcc" ]]; then
	make -j${KEBABS} O=out
else
	make -j${KEBABS} O=out ARCH=arm64 CC="/home/runner/${SEMAPHORE_PROJECT_NAME}/clang/clang-r349610/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc32/bin/arm-linux-androideabi-"
fi
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip for oos
if [[ ${BUILDFOR} == *"oos"* ]]; then
	mkdir anykernel/modules
	mkdir anykernel/modules/vendor
	mkdir anykernel/modules/vendor/lib
	mkdir anykernel/modules/vendor/lib/modules
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
	cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/modules/vendor/lib/modules
	mv $(pwd)/anykernel/modules/vendor/lib/modules/wlan.ko $(pwd)/anykernel/modules/vendor/lib/modules/qca_cld3_wlan.ko
	${STRIP} --strip-unneeded $(pwd)/anykernel/modules/vendor/lib/modules/qca_cld3_wlan.ko
fi

# prepare zip for custom
if [[ ${BUILDFOR} == *"custom"* ]]; then
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
fi


# POST ZIP OR FAILURE
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${BUILDFOR}" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} pushed to CI Channel!" -d chat_id=${KERNEL_CHAT_ID}
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="The compiler decides to scream at @idkwhoiam322 for ruining ${BUILDFOR}" -d chat_id=${KERNEL_CHAT_ID}
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
	exit 1;
fi
rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb && rm -rf modules
cd ..
if [[ ${BUILDFOR} == *"oos"* ]]; then
curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/out/include/generated/compile.h" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
fi

	if [[ ${BUILDFOR} == *"custom"* ]]; then
		export DEFCONFIG=weebomni_defconfig
		export BUILDFOR=omni
	if [[ "$@" =~ "stable"* ]]; then 
		export ZIPNAME="${BUILDFOR}${VERSION}.zip"
	else
		export ZIPNAME="${KERNEL_BUILD_TYPE}-r${SEMAPHORE_BUILD_NUMBER}-${BUILDFOR}-$(git rev-parse --abbrev-ref HEAD)-$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')$(grep "EXTRAVERSION =" < Makefile | awk '{print $3}').zip"
	fi
	START=$(date +"%s")
	make O=out ARCH=arm64 $DEFCONFIG
	if [[ "$@" =~ "gcc" ]]; then
		make -j${KEBABS} O=out
	else
		make -j${KEBABS} O=out ARCH=arm64 CC="/home/runner/${SEMAPHORE_PROJECT_NAME}/clang/clang-r349610/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="/home/runner/${SEMAPHORE_PROJECT_NAME}/gcc32/bin/arm-linux-androideabi-"
	fi
	END=$(date +"%s")
	DIFF=$((END - START))

	# prepare zip for omni
		mkdir anykernel/modules
		mkdir anykernel/modules/system
		mkdir anykernel/modules/system/lib
		mkdir anykernel/modules/system/lib/modules
		cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
		cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/modules/system/lib/modules
		${STRIP} --strip-unneeded $(pwd)/anykernel/modules/system/lib/modules/wlan.ko

	# final push
	cd anykernel
	zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
	CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')

	if (($((CHECKER / 1048576)) > 5)); then
		curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${BUILDFOR}" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
		curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
		curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} pushed to CI Channel!" -d chat_id=${KERNEL_CHAT_ID}
	else
		curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="The compiler decides to scream at @idkwhoiam322 for ruining ${BUILDFOR}" -d chat_id=${KERNEL_CHAT_ID}
		curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
		exit 1;
	fi
	rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb && rm -rf modules
	cd ..
fi
