#!/bin/bash

# get environment variables
source env_vars.sh

cd ${PROJECT_DIR} || exit

if [[ ${CI_ENVIRONMENT} == "SEMAPHORE_CI" ]]; then
	sudo install-package --update-new autogen bc ccache git-core guile-2.0-libs \
			libgc1c2 libopts25-dev bash gnupg
fi

git clone https://github.com/idkwhoiam322/AnyKernel3.git -b op7 --depth=1 anykernel3

if [[ ${COMPILER} == "GCC" ]]; then
	git clone https://github.com/arter97/arm64-gcc.git -b master --depth=1 gcc
	git clone https://github.com/arter97/arm32-gcc.git -b master --depth=1 gcc32
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 gcc
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 --depth=1 gcc32
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd ${PROJECT_DIR}/clang
	find . | grep -v 'clang-r377782b' | xargs rm -rf
	cd ${PROJECT_DIR}
fi
