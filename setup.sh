#!/bin/bash
cd ..
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev

git clone https://github.com/whoknowswhoiam/weebanykernel3.git -b android10 anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/kdrag0n/aarch64-elf-gcc -b 9.x --depth=3 gcc
	git clone https://github.com/kdrag0n/arm-eabi-gcc -b 9.x --depth=3 gcc32
	cd gcc
	git checkout 14e746a95f594cf841bdf8c2e6122c274da7f70b
	cd ../gcc32
	git checkout 76c68effb613ff240ecad714f6c6f63368e91478
	cd ..
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b ndk-r19 --depth=1 gcc
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b ndk-r19 --depth=1 gcc32
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd clang
	ls
	find . | grep -v 'clang-r365631c' | xargs rm -rf
	ls
	cd ..
fi
