#!/bin/bash
cd ..
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev

git clone https://github.com/whoknowswhoiam/weebanykernel2.git -b wip anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone git://github.com/krasCGQ/aarch64-linux-android -b opt-gnu-8.x --depth=1 gcc
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 gcc
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd clang
	rm -rf clang-3289846 && rm -rf clang-4679922 && rm -rf clang-r328903 && rm -rf clang-r339409b && rm -rf clang-4679922 && rm -rf clang-3289846 && rm -rf clang-r328903 && rm -rf clang-r339409b && rm -rf clang-r344140b
	ls
	cd ..
fi
