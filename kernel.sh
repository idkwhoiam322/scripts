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

# Export versions
export KBUILD_BUILD_VERSION=1
export LOCALVERSION=`echo ${VERSION}`

# Set COMPILER
if [[ "$@" =~ "gcc" ]]; then
	export COMPILER=GCC
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-gnu-"
	export STRIP="$(pwd)/gcc/bin/aarch64-linux-gnu-strip"
	
else
	export COMPILER=DTC9
	export KBUILD_COMPILER_STRING="$($(pwd)/dtc9/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
	export STRIP=$(pwd)/gcc/bin/aarch64-linux-android-strip
	export CC="$(pwd)/dtc9/bin/clang"
	export CLANG_TRIPLE=aarch64-linux-gnu-
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"
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

export ZIPNAME="${COMPILER,,}-${BUILDFOR}-r${SEMAPHORE_BUILD_NUMBER}-${VERB}.zip"

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then 
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>BETA</code>
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
make -j${KEBABS} O=out
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

if [[ ${BUILDFOR} == *"custom"* ]]; then
	export DEFCONFIG=weebomni_defconfig
	export BUILDFOR=omni
	export ZIPNAME="${COMPILER,,}-${BUILDFOR}-r${SEMAPHORE_BUILD_NUMBER}-${VERB}.zip"
	START=$(date +"%s")
	make O=out ARCH=arm64 $DEFCONFIG
	make -j${KEBABS} O=out
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
fi
