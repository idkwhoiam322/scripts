#!/bin/bash

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
	CLANG_PATH=${PROJECT_DIR}/clang/clang-r377782b
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
	VERB="$(date +%Y%m%d)-$(echo ${MIN_HEAD:0:8})"
	VERSION="${VERA}-${VERB}-r${CUR_BUILD_NUM}"
	ZIPNAME="${MY_DEVICE}-${CUR_BRANCH}-r${CUR_BUILD_NUM}.zip"
elif [[ ${KERNEL_BUILD_TYPE} == *"STABLE"* ]]; then
	KERNEL_BUILD_TYPE="Stable"
	VERA="Weeb-Kernel"
	VERSION="${VERA}-v${RELEASE_VERSION}-${RELEASE_CODENAME}"
	ZIPNAME="${VERSION}.zip"
fi
export LOCALVERSION=$(echo "-${VERSION}")
export ZIPNAME KERNEL_BUILD_TYPE

#export defconfig
DEFCONFIG="weeb_defconfig"
export DEFCONFIG
