#!/bin/bash
cd ..
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev

git clone https://github.com/whoknowswhoiam/weebanykernel2.git -b pie anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/RaphielGang/aarch64-raph-linux-android.git gcc
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 gcc
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd clang
	ls
	rm -rf clang-3289846 && rm -rf clang-4679922 && rm -rf clang-r328903 && rm -rf clang-r339409b && rm -rf clang-4679922 && rm -rf clang-3289846 && rm -rf clang-r328903 && rm -rf clang-r339409b && rm -rf clang-r344140b && rm -rf clang-r346389 && rm -rf clang-stable
	ls
	cd ..
fi
