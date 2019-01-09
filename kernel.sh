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
	
else
	export COMPILER=CLANG
fi
# remove any old residue
rm -rf $(pwd)/anykernel/ramdisk/modules/wlan.ko
rm -rf $(pwd)/anykernel/Image.gz-dtb

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi

export ARCH=arm64

if [[ ${COMPILER} == *"CLANG"* ]]; then
	export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r346389b/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
	export STRIP=$(pwd)/gcc/bin/aarch64-linux-android-strip
	export CC="$(pwd)/clang/clang-r346389b/bin/clang"
	export CLANG_TRIPLE=aarch64-linux-gnu-
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"

		if [[ "$@" =~ "oos"* ]]; then 
			export DEFCONFIG=weeb_defconfig
			export BUILDFOR=oos
		fi

		if [[ "$@" =~ "custom"* ]]; then
			export DEFCONFIG=weebcustom_defconfig
			export BUILDFOR=custom
		fi
fi

if [[ ${COMPILER} == *"GCC"* ]]; then
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-opt-linux-android-"
	export STRIP="$(pwd)/gcc/bin/aarch64-opt-linux-android-strip"

		if [[ "$@" =~ "oos"* ]]; then 
			export DEFCONFIG=weeb_defconfig
			export BUILDFOR=oos
		fi

		if [[ "$@" =~ "custom"* ]]; then		
			export DEFCONFIG=weebcustom_defconfig
			export BUILDFOR=custom
		fi 
fi

export ZIPNAME="weeb-${COMPILER,,}-${oos}-r${SEMAPHORE_BUILD_NUMBER}-${VERB}.zip"

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then 
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>BETA</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on semaphore_ci....</i>" -d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
fi

curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="<code> // Compilation Started on Semaphore CI // </code>" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML

# compilation
START=$(date +"%s")
make O=out ARCH=arm64 $DEFCONFIG
make -j${KEBABS} O=out
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip for oos
if [[ ${BUILDFOR} == *"oos"* ]]; then
	mkdir anykernel/ramdisk/modules
	rm -rf anykernel/ramdisk/init.qcomcustom.rc
	rm -rf anykernel/ramdisk/init.weebcustom.sh
	mv anykernel/ramdisk/init.qcomoos.rc anykernel/ramdisk/init.qcom.rc
	mv anykernel/ramdisk/init.weeboos.sh anykernel/ramdisk/init.weeb.sh
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
	cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
	${STRIP} --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
fi

# prepare zip for cusotm
if [[ ${BUILDFOR} == *"custom"* ]]; then
	rm -rf anykernel/ramdisk/init.supolicy.sh
	rm -rf anykernel/patch
	rm -rf anykernel/ramdisk/init.qcomoos.rc
	rm -rf anykernel/ramdisk/init.weeboos.sh
	mv anykernel/ramdisk/init.qcomcustom.rc anykernel/ramdisk/init.qcom.rc
	mv anykernel/ramdisk/init.weebcustom.sh anykernel/ramdisk/init.weeb.sh
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
fi

# POST ZIP OR FAILURE
cd anykernel
zip -r9 ${ZIPNAME} * -x README.md ${ZIPNAME}
CHECKER=$(ls -l ${ZIPNAME} | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${BUILDFOR}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
	curl -F chat_id="${CI_CHANNEL_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_KEY}/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="The compiler decides to scream at @idkwhoiam322 for ruining ${BUILDFOR}" -d chat_id=${KERNEL_CHAT_ID}
	curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=${CI_CHANNEL_ID}
fi
