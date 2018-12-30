#!/bin/bash
cd ..
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev

git clone https://github.com/whoknowswhoiam/weebanykernel2.git -b pie anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone git://github.com/krasCGQ/aarch64-linux-android -b opt-gnu-8.x --depth=1 gcc
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 gcc
	git https://github.com/whoknowswhoiam/clang.git -b master --depth=1 clang
fi
