#!/bin/bash
cd ..
# PREPPING

# Set COMPILERE
if [[ "$@" =~ "gcc" ]]; then
	export COMPILER=GCC
else
	export COMPILER=CLANG
fi
# remove any old residue
rm -rf $(pwd)/anykernel/ramdisk/modules/wlan.ko
rm -rf $(pwd)/anykernel/kernels/oos/Image.gz-dtb
rm -rf $(pwd)/anykernel/kernels/custom/Image.gz-dtb

# Make common kernel folder
mkdir anykernel/kernels

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
	COUNT="$(grep -c '^processor' /proc/cpuinfo)"
	export KEBABS="$((COUNT * 2))"
fi

export ARCH=arm64

if [[ ${COMPILER} == *"CLANG"* ]]; then
	# tmpfs bes
	mkdir -pv out
	sudo mount -t tmpfs -o size=4g tmpfs out
	sudo chown "${USER}" out/ -R
	
	export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r346389b/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
	export STRIP=$(pwd)/gcc/bin/aarch64-linux-android-strip
	export CC="$(pwd)/clang/clang-r346389b/bin/clang"
	export CLANG_TRIPLE=aarch64-linux-gnu-
	export CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"

		if [[ ${SEMAPHORE_PROJECT_NAME} == *"oostest"* ]]; then 
			export DEFCONFIG=weeb_defconfig
			export BUILDFOR=oos
			export ZIPNAME="weebkernel_oos_r$SEMAPHORE_BUILD_NUMBER.zip"
			mkdir anykernel/kernels/oos
			mkdir anykernel/ramdisk/modules
		fi

		if [[ ${SEMAPHORE_PROJECT_NAME} == *"customtest"* ]]; then
			export DEFCONFIG=weebcustom_defconfig
			export BUILDFOR=custom
			export ZIPNAME="weebkernel_custom_r$SEMAPHORE_BUILD_NUMBER.zip"
			mkdir anykernel/kernels/custom
		fi
fi

if [[ ${COMPILER} == *"GCC"* ]]; then
	export CROSS_COMPILE=$(pwd)/gcc/bin/aarch64-opt-linux-android-
	export STRIP=$(pwd)/gcc/bin/aarch64-opt-linux-android-strip
	export DEFCONFIG=weebcustom_defconfig
	export BUILDFOR=custom
	export ZIPNAME="Custom_GCC_r$SEMAPHORE_BUILD_NUMBER.zip"
	mkdir anykernel/kernels/custom
fi

# Telegram Post to CI channel
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Kernel: <code>Weeb Kernel</code>
Type: <code>BETA</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>$COMPILER</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
ROM Support: <code>$BUILDFOR</code>
<i>Build started....</i>" -d chat_id=$CHAT_ID -d parse_mode=HTML

# compilation
START=$(date +"%s")
make O=out ARCH=arm64 $DEFCONFIG
make -j${KEBABS} O=out
END=$(date +"%s")
DIFF=$((END - START))

# prepare zip for oos
if [[ ${BUILDFOR} == *"oos"* ]]; then
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/oos/
	cp $(pwd)/out/drivers/staging/qcacld-3.0/wlan.ko $(pwd)/anykernel/ramdisk/modules
	$STRIP --strip-unneeded $(pwd)/anykernel/ramdisk/modules/wlan.ko
	find $(pwd)/anykernel/ramdisk/modules -name '*.ko' -exec $(pwd)/out/scripts/sign-file sha512 $(pwd)/out/certs/signing_key.pem $(pwd)/out/certs/signing_key.x509 {} \;
fi


if [[ ${BUILDFOR} == *"custom"* ]]; then
	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/
fi



# POST ZIP OR FAILURE
cd anykernel
rm -rf nontreble.sh
mv treble.sh anykernel.sh
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
CHECKER=$(ls -l $ZIPNAME | awk '{print $5}')

if (($((CHECKER / 1048576)) > 5)); then
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build Version: <code>r$SEMAPHORE_BUILD_NUMBER</code>
Compilation Time: <code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</code>
ROM Support: <code>$BUILDFOR</code>
<i>Uploading....</i>" -d chat_id=$CHAT_ID -d parse_mode=HTML
	curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="The compiler decides to scream at @idkwhoiam322" -d chat_id=$CHAT_ID	
fi
