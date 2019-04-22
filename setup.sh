#!/bin/bash
cd ..
sudo install-package --update-new ccache bc bash git-core gnupg build-essential \
		zip curl make automake autogen autoconf autotools-dev libtool shtool python \
		m4 gcc libtool zlib1g-dev

git clone https://github.com/whoknowswhoiam/weebanykernel2.git -b pie anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/RaphielGang/aarch64-raph-linux-android.git -b master gcc
	git clone https://github.com/RaphielGang/arm-linux-gnueabi-8.x.git -b master gcc32
else
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=6 gcc
	cd gcc && git reset --hard e54105c9f893a376232e0fc539c0e7c01c829b1e && cd ..
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 --depth=6 gcc32
	cd gcc32 && git reset --hard b91992b549430ac1a8a684f4bfe8c95941901165 && cd .. 
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd clang
	ls
	find . | grep -v 'clang-r353983c' | xargs rm -rf
	ls
	cd ..
fi
