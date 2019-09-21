#!/bin/bash
cd ..
rm -rf out
# PREPPING

# Set Kernel Info
export VERA="-Hentai-o-W-o"
export VERB_SET=$(git rev-parse HEAD)
export VERB="$(date +%Y%m%d)-$(echo ${VERB_SET:0:4})"
VERSION="${VERA}-${VERB}-r${DRONE_BUILD_NUMBER}"

# Export User and Host
export KBUILD_BUILD_USER=idkwhoiam322
export KBUILD_BUILD_HOST=raphielgangci

# Release type
if [[ "$@" =~ "beta"* ]]; then
	export KERNEL_BUILD_TYPE="beta"
elif [[ "$@" =~ "stable"* ]]; then
	export VERA="-Weeb-Kernel"
	export KERNEL_BUILD_TYPE="Stable"
	export VERSION="${VERA}-${KERNEL_BUILD_TYPE}-v${RELEASE_VERSION}-${RELEASE_CODENAME}"
fi

# Export versions
export KBUILD_BUILD_VERSION=204
export LOCALVERSION=`echo ${VERSION}`

# Set COMPILER
if [[ "$@" =~ "gcc" ]]; then
	export COMPILER=GCC
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-elf-"
	export CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-eabi-"
	export STRIP="$(pwd)/gcc/bin/aarch64-elf-strip"
	
else
	export COMPILER=CLANG
	export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r353983e/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
	export STRIP="$(pwd)/gcc/bin/aarch64-linux-gnu-strip"
fi
export ARCH=arm64 && export SUBARCH=arm64

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi


if [[ "$@" =~ "stable"* ]]; then 
	export ZIPNAME="${BUILDFOR}${VERSION}.zip"
else
	export ZIPNAME="${KERNEL_BUILD_TYPE}-r${DRONE_BUILD_NUMBER}-${BUILDFOR}-$(git rev-parse --abbrev-ref HEAD).$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')$(grep "EXTRAVERSION =" < Makefile | awk '{print $3}').zip"
fi

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then 
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>${KERNEL_BUILD_TYPE^^}</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Build Number: <code>r${DRONE_BUILD_NUMBER}</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on drone_ci....</i>" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build started for revision ${DRONE_BUILD_NUMBER}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
fi


# compilation
START=$(date +"%s")
make O=out ARCH=arm64 $DEFCONFIG
if [[ "$@" =~ "gcc" ]]; then
	make -j${KEBABS} O=out ARCH=arm64
else
	make -j${KEBABS} O=out ARCH=arm64 CC="/drone/src/clang/clang-r353983e/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/drone/src/gcc/bin/aarch64-linux-gnu-" CROSS_COMPILE_ARM32="/drone/src/gcc32/bin/arm-linux-gnueabi-"
fi
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip for oos
if [[ ${BUILDFOR} == *"oos"* ]]; then
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
fi

# prepare zip for custom
if [[ ${BUILDFOR} == *"custom"* ]] || [[ ${BUILDFOR} == *"hax"* ]]; then
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
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/out/System.map" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
rm -rf out

	if [[ ${BUILDFOR} == *"custom"* ]]; then
		export DEFCONFIG=weebomni_defconfig
		export BUILDFOR=omni
	if [[ "$@" =~ "stable"* ]]; then 
		export ZIPNAME="${BUILDFOR}${VERSION}.zip"
	else
		export ZIPNAME="${KERNEL_BUILD_TYPE}-r${DRONE_BUILD_NUMBER}-${BUILDFOR}-$(git rev-parse --abbrev-ref HEAD).$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')$(grep "EXTRAVERSION =" < Makefile | awk '{print $3}').zip"
	fi
	START=$(date +"%s")
	make O=out ARCH=arm64 $DEFCONFIG
	if [[ "$@" =~ "gcc" ]]; then
	make -j${KEBABS} O=out ARCH=arm64
	else
		make -j${KEBABS} O=out ARCH=arm64 CC="/drone/src/clang/clang-r353983e/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="/drone/src/gcc/bin/aarch64-linux-gnu-" CROSS_COMPILE_ARM32="/drone/src/gcc32/bin/arm-linux-gnueabi-"
	fi
	END=$(date +"%s")
	DIFF=$((END - START))

	# prepare zip for omni
		cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel

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
