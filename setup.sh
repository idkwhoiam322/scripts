#!/bin/bash
cd ..
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev

git clone https://github.com/whoknowswhoiam/weebanykernel2.git -b pie anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/RaphielGang/aarch64-linux-gnu-8.x gcc
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 --depth=1 gcc32
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 gcc
	git clone https://github.com/celtare21/toolchains.git -b dtc9 --depth=1 dtc9
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 --depth=1 gcc32
fi
