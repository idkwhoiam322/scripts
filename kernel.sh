#!/bin/bash

# get environment variables
source env_vars.sh

cd ${PROJECT_DIR} || exit

if [[ ${BUILDFOR} == *"oos"* ]]; then
	git fetch origin oos
	git checkout oos
fi

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage \
-d text="Kernel: <code>Weeb Kernel</code>
Type: <code>${KERNEL_BUILD_TYPE^^}</code>
Device: <code>OnePlus 5/T</code>
Compiler: <code>${COMPILER}</code>
Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Build Number: <code>r${CUR_BUILD_NUM}</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build started on ${CI_ENVIRONMENT}....</i>" \
-d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
fi

#
# compilation
#
# First we need number of jobs
COUNT="$(grep -c '^processor' /proc/cpuinfo)"
export JOBS="$((COUNT * 2))"

export ARCH=arm64
export SUBARCH=arm64

START=$(date +"%s")
make O=out ${DEFCONFIG}
if [[ ${COMPILER} == "GCC" ]]; then
	make -j${JOBS} O=out
else
	export KBUILD_COMPILER_STRING="$(${CLANG_PATH}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";

	LD_LIBRARY_PATH="${CLANG_PATH}/lib:${CLANG_PATH}/lib64${LD_LIBRARY_PATH}" \
	PATH="${CLANG_PATH}/bin:${PROJECT_DIR}/gcc/bin:${PROJECT_DIR}/gcc32/bin:${PATH}" \
	make O=out -j${JOBS} \
	CC="${CLANG_PATH}/bin/clang" \
	CLANG_TRIPLE="aarch64-linux-gnu-" \
	CROSS_COMPILE="${PROJECT_DIR}/gcc/bin/aarch64-linux-android-" \
	CROSS_COMPILE_ARM32="${PROJECT_DIR}/gcc32/bin/arm-linux-androideabi-"
fi

END=$(date +"%s")
DIFF=$((END - START))

if [ ! -f "${OUT_IMAGE_DIR}" ]; then
	curl -s -X POST https://api.telegram.org/bot"${BOT_API_KEY}"/sendMessage -d text="Build throwing err0rs yO" -d chat_id="${CI_CHANNEL_ID}"
	exit 1;
fi

if [[ ${BUILDFOR} == *"oos"* ]]; then
# Make folder for wlan module in anykernel3
	mkdir -p ${ANYKERNEL_DIR}/modules/vendor/lib/modules
# Move WLAN module to anykernel3
	cp ${PROJECT_DIR}/out/drivers/staging/qcacld-3.0/wlan.ko ${ANYKERNEL_DIR}/modules/vendor/lib/modules/qca_cld3_wlan.ko
fi

# Move kernel image to anykernel3 folder
cp ${OUT_IMAGE_DIR} ${ANYKERNEL_DIR}

# POST ZIP OR REPORT FAILURE
cd ${ANYKERNEL_DIR}
zip -r9 "${ZIPNAME}" -- *

curl -F chat_id="${CI_CHANNEL_ID}" \
	-F caption="sha1sum: $(sha1sum ${ZIPNAME} | awk '{ print $1 }')" \
	-F document=@"$(pwd)/${ZIPNAME}" \
	https://api.telegram.org/bot"${BOT_API_KEY}"/sendDocument

# Weeb/Hentai patch for custom boot.img

# Patch kernel image for magisk
magiskboot=${script_dir}/bin/magiskboot

chmod 777 $magiskboot
#$magiskboot decompress $comp_image $decomp_image;
#$magiskboot hexpatch $decomp_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
#$magiskboot compress=gzip $decomp_image $comp_image;

mkdir -p ${script_dir}/out ${script_dir}/temp

cd ${script_dir}/temp
$magiskboot unpack ${script_dir}/boot/$BOOT_IMG_NAME || { echo '$BOOT_IMG_NAME not found!' ; exit 1; }
rm -rf kernel kernel_dtb

cp ${ANYKERNEL_DIR}/Image.gz-dtb ${script_dir}/temp
$magiskboot split Image.gz-dtb
rm -rf Image.gz-dtb

$magiskboot repack ${script_dir}/boot/$BOOT_IMG_NAME ${script_dir}/out/${NEW_BOOT_IMG_NAME}

curl -F chat_id="${CI_CHANNEL_ID}" \
	-F document=@"${script_dir}/out/${NEW_BOOT_IMG_NAME}" \
	https://api.telegram.org/bot"${BOT_API_KEY}"/sendDocument
