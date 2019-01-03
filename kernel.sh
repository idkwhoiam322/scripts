#!/bin/bash
cd ..
# PREPPING

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
			export ZIPNAME="weebkernel_oos_v2.0r$SEMAPHORE_BUILD_NUMBER.zip"
		fi

		if [[ "$@" =~ "custom"* ]]; then
			export DEFCONFIG=weebcustom_defconfig
			export BUILDFOR=custom
			export ZIPNAME="weebkernel_custom_v2.0r$SEMAPHORE_BUILD_NUMBER.zip"
		fi
fi

if [[ ${COMPILER} == *"GCC"* ]]; then
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-opt-linux-android-"
	export STRIP="$(pwd)/gcc/bin/aarch64-opt-linux-android-strip"

		if [[ "$@" =~ "oos"* ]]; then 
			export DEFCONFIG=weeb_defconfig
			export BUILDFOR=oos
			export ZIPNAME="weebkernel_oos_v2.0r$SEMAPHORE_BUILD_NUMBER.zip"
		fi

		if [[ "$@" =~ "custom"* ]]; then		
			export DEFCONFIG=weebcustom_defconfig
			export BUILDFOR=custom
			export ZIPNAME="weebkernel_custom_v2.0r$SEMAPHORE_BUILD_NUMBER.zip"
		fi 
fi

# Telegram Post to CI channel
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>BETA</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>$COMPILER</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
ROM Support: <code>$BUILDFOR</code>
<i>Build started on semaphore_ci....</i>" -d chat_id=$CI_CHANNEL_ID -d parse_mode=HTML

curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="<code> // Compilation Started on Semaphore CI // </code>" -d chat_id=$KERNEL_CHAT_ID -d parse_mode=HTML

# compilation
START=$(date +"%s")
make O=out ARCH=arm64 $DEFCONFIG
make -j${KEBABS} O=out
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip for oos
if [[ ${BUILDFOR} == *"oos"* ]]; then
	mkdir anykernel/ramdisk/modules
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
	cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
	$STRIP --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
fi

# prepare zip for cusotm
if [[ ${BUILDFOR} == *"custom"* ]]; then
	mkdir anykernel/ramdisk/modules
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
	cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
	$STRIP --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
fi

# POST ZIP OR FAILURE
cd anykernel
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
CHECKER=$(ls -l $ZIPNAME | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for $BUILDFOR" -d chat_id=$KERNEL_CHAT_ID -d parse_mode=HTML
	curl -F chat_id="$CI_CHANNEL_ID" -F document=@"$(pwd)/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="The compiler decides to scream at @idkwhoiam322" -d chat_id=$KERNEL_CHAT_ID
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build for ${BUILDFOR} throwing err0rs yO" -d chat_id=$CI_CHANNEL_ID	
fi
