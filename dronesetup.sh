#!/bin/bash
cd ..

git clone https://github.com/whoknowswhoiam/weebanykernel3.git -b pie anykernel


if [[ "$@" =~ "gcc" ]]; then
	git clone https://github.com/kdrag0n/aarch64-elf-gcc -b 9.x --depth=1 gcc
	git clone https://github.com/kdrag0n/arm-eabi-gcc -b 9.x --depth=1 gcc32
else
	git clone https://github.com/RaphielGang/aarch64-linux-gnu-8.x.git --depth=1 gcc
	git clone https://github.com/RaphielGang/arm-linux-gnueabi-8.x.git --depth=1 gcc32
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	cd clang
	ls
	find . | grep -v 'clang-r353983d' | xargs rm -rf
	ls
	cd ..
fi
