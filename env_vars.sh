#!/bin/bash

# Tell env that this is a standalone build
IS_KERNEL_STANDALONE=y
export IS_KERNEL_STANDALONE

# Export custom User and Host
KBUILD_BUILD_USER=idkwhoiam322
KBUILD_BUILD_HOST=raphielgang_ci
export KBUILD_BUILD_USER KBUILD_BUILD_HOST

# Get CI environment
if [ -d "/home/runner/" ]; then
	CI_ENVIRONMENT="SEMAPHORE_CI"
	PROJECT_DIR=/home/runner/${SEMAPHORE_PROJECT_NAME}
	CUR_BUILD_NUM="${SEMAPHORE_BUILD_NUMBER}"
fi
export CI_ENVIRONMENT PROJECT_DIR CUR_BUILD_NUM

cd ${PROJECT_DIR} || exit

# AnyKernel3
ANYKERNEL_DIR="${PROJECT_DIR}/anykernel3"
export ANYKERNEL_DIR

if [[ ${COMPILER} == *"GCC"* ]]; then
	CROSS_COMPILE="${PROJECT_DIR}/gcc/bin/aarch64-elf-"
	CROSS_COMPILE_ARM32="${PROJECT_DIR}/gcc32/bin/arm-eabi-"
else
	CLANG_PATH=${PROJECT_DIR}/clang
fi
export COMPILER CROSS_COMPILE CROSS_COMPILE_ARM32

# get current branch and kernel patch level
CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export CUR_BRANCH

# Release type
if [[ ${KERNEL_BUILD_TYPE} == *"BETA"* ]]; then
	KERNEL_BUILD_TYPE="beta"
	VERA="Hentai"
	MY_DEVICE="op7pro"
	MIN_HEAD=$(git rev-parse HEAD)
	VERB="$(echo ${MIN_HEAD:0:8})"
	VERSION="${VERA}-${VERB}-${CUR_BRANCH}-r${CUR_BUILD_NUM}"
	ZIPNAME="${MY_DEVICE}-${CUR_BRANCH}-r${CUR_BUILD_NUM}.zip"
	NEW_BOOT_IMG_NAME="$(git rev-parse --abbrev-ref HEAD)-r${CUR_BUILD_NUM}-boot.img"
elif [[ ${KERNEL_BUILD_TYPE} == *"STABLE"* ]]; then
	KERNEL_BUILD_TYPE="Stable"
	VERA="Weeb-Kernel"
	VERSION="${VERA}-v${RELEASE_VERSION}-${RELEASE_CODENAME}-$(git rev-parse --abbrev-ref HEAD | cut -d '-' -f 1)"
	ZIPNAME="${VERSION}.zip"
	NEW_BOOT_IMG_NAME="v${RELEASE_VERSION}-${RELEASE_CODENAME}-$(git rev-parse --abbrev-ref HEAD | cut -d '-' -f 1)-boot.img"
fi
export LOCALVERSION=$(echo "-${VERSION}")
export ZIPNAME KERNEL_BUILD_TYPE

#export defconfig
DEFCONFIG="weeb_defconfig"
export DEFCONFIG

# boot image setup
script_dir=${PROJECT_DIR}/script
BOOT_IMG_NAME="boot.img"
export script_dir BOOT_IMG_NAME NEW_BOOT_IMG_NAME
