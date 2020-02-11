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

START=$(date +"%s")
make O=out ARCH=arm64 ${DEFCONFIG}
if [[ ${COMPILER} == "GCC" ]]; then
	make -j${JOBS} O=out ARCH=arm64
else
	make O=out -j${JOBS} ARCH=arm64 CC=$CC CLANG_TRIPLE=$CLANG_TRIPLE CROSS_COMPILE=$CROSS_COMPILE CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32
fi
END=$(date +"%s")
DIFF=$((END - START))

if [ ! -f "${OUT_IMAGE_DIR}" ]; then
	curl -s -X POST https://api.telegram.org/bot"${BOT_API_KEY}"/sendMessage -d text="Build throwing err0rs yO" -d chat_id="${CI_CHANNEL_ID}"
	exit 1;
fi

# Move kernel image to anykernel3 folder
cp ${OUT_IMAGE_DIR} ${ANYKERNEL_DIR}

# POST ZIP OR REPORT FAILURE
cd ${ANYKERNEL_DIR}
zip -r9 "${ZIPNAME}" -- *

curl -s -X POST https://api.telegram.org/bot${BOT_API_KEY}/sendMessage \
	-d text="Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds!" \
	-d chat_id=${CI_CHANNEL_ID} -d parse_mode=HTML
curl -F chat_id="${CI_CHANNEL_ID}" \
	-F caption="sha1sum: $(sha1sum ${ZIPNAME} | awk '{ print $1 }')" \
	-F document=@"$(pwd)/${ZIPNAME}" \
	https://api.telegram.org/bot"${BOT_API_KEY}"/sendDocument

rm -rf ${ZIPNAME} && rm -rf Image.gz-dtb && rm -rf modules
cd ..
