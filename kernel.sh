#!/bin/bash

# get environment variables
source env_vars.sh

cd ${PROJECT_DIR} || exit

# Telegram Post to CI channel
if [[ "$@" =~ "post"* ]]; then
curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage \
-d text="Kernel: <code>Weeb Kernel</code>
Type: <code>${KERNEL_BUILD_TYPE^^}</code>
Device: <code>OnePlus 7/T/Pro/5G</code>
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
	export KBUILD_COMPILER_STRING="$(${CLANG_PATH}/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')";

	PATH="${CLANG_PATH}/bin:${PATH}" \
	make O=out -j${JOBS} \
	CC="clang" \
	CLANG_TRIPLE="aarch64-linux-gnu-" \
	CROSS_COMPILE="aarch64-linux-gnu-" \
	CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
	LD=ld.lld \
	AR=llvm-ar \
	NM=llvm-nm \
	OBJCOPY=llvm-objcopy \
	OBJDUMP=llvm-objdump \
	STRIP=llvm-strip
fi

END=$(date +"%s")
DIFF=$((END - START))

export OUT_IMAGE="${PROJECT_DIR}/out/arch/arm64/boot/Image.gz"

if [ ! -f "${OUT_IMAGE}" ]; then
	curl -s -X POST https://api.telegram.org/bot"${BOT_API_KEY}"/sendMessage -d text="Build throwing err0rs yO" -d chat_id="${CI_CHANNEL_ID}"
	exit 1;
fi

# Move kernel image and dtb to anykernel3 folder
cp ${OUT_IMAGE} ${ANYKERNEL_DIR}
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > ${ANYKERNEL_DIR}/dtb

# POST ZIP OR REPORT FAILURE
cd ${ANYKERNEL_DIR}
zip -r9 "${ZIPNAME}" -- *

curl -F chat_id="${CI_CHANNEL_ID}" \
	-F caption="sha1sum: $(sha1sum ${ZIPNAME} | awk '{ print $1 }')" \
	-F document=@"$(pwd)/${ZIPNAME}" \
	https://api.telegram.org/bot"${BOT_API_KEY}"/sendDocument

# Weeb/Hentai patch for custom boot.img
mkbootimg=${script_dir}/bin/mkbootimg
unpackbootimg=${script_dir}/bin/unpackbootimg

chmod 777 $mkbootimg $unpackbootimg

mkdir -p ${script_dir}/out

cd ${script_dir}/boot

export OS="10.0.0"
export SPL="2020-06"

$mkbootimg \
    --kernel ${ANYKERNEL_DIR}/Image.gz \
    --ramdisk ${script_dir}/ramdisk.gz \
    --cmdline 'androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 androidboot.vbmeta.avb_version=1.0 buildvariant=user' \
    --base           0x00000000 \
    --pagesize       4096 \
    --kernel_offset  0x00008000 \
    --ramdisk_offset 0x02000000 \
    --second_offset  0x00f00000 \
    --tags_offset    0x00000100 \
    --dtb            ${ANYKERNEL_DIR}/dtb \
    --dtb_offset     0x01f00000 \
    --os_version     $OS \
    --os_patch_level $SPL \
    --header_version 2 \
    -o ${script_dir}/out/${NEW_BOOT_IMG_NAME}

# Sleep to prevent errors such as:
# {"ok":false,"error_code":429,"description":"Too Many Requests: retry after 8","parameters":{"retry_after":8}}
sleep 2;
curl -F chat_id="${CI_CHANNEL_ID}" \
	-F document=@"${script_dir}/out/${NEW_BOOT_IMG_NAME}" \
	https://api.telegram.org/bot"${BOT_API_KEY}"/sendDocument
