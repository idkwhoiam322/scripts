#!/bin/bash

# get environment variables
source env_vars.sh

cd ${PROJECT_DIR} || exit

if [[ ${CI_ENVIRONMENT} == "SEMAPHORE_CI" ]]; then
	sudo install-package --update-new autogen bc ccache git-core guile-2.0-libs \
			libgc1c2 libopts25-dev bash gnupg
fi

git clone https://github.com/idkwhoiam322/AnyKernel3.git -b android10 --depth=1 anykernel3

if [[ ${COMPILER} == "GCC" ]]; then
	git clone https://github.com/kdrag0n/aarch64-elf-gcc -b 9.x --depth=3 gcc
	git clone https://github.com/kdrag0n/arm-eabi-gcc -b 9.x --depth=3 gcc32
	cd ${PROJECT_DIR}/gcc
	git checkout 14e746a95f594cf841bdf8c2e6122c274da7f70b
	cd ${PROJECT_DIR}/gcc32
	git checkout 76c68effb613ff240ecad714f6c6f63368e91478
	cd ${PROJECT_DIR}
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b ndk-r19 --depth=1 gcc
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b ndk-r19 --depth=1 gcc32
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd ${PROJECT_DIR}/clang
	find . | grep -v 'clang-r370808' | xargs rm -rf
	cd ${PROJECT_DIR}
fi
