#!/bin/bash
cd ..

export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r344140b/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
rm -rf out
mkdir -p out

#	Let's compile this mess
#
#	Time for Non-Treble
#
rm -rf out
mkdir -p out
make O=out ARCH=arm64 weebcustom_defconfig
chmod +x -R $(pwd)/

make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r344140b/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"s

#	Success
#	Preparing Kernel ZIP
mkdir anykernel/kernels
mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/


#	ReZIP the Kernel
cd $(pwd)/anykernel
rm -rf treble.sh
mv nontreble.sh anykernel.sh
ZIPNAME="WeebKerneL-NonTreble_V1.13.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME

#	Time to push the Kernel ZIP
cd ..
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/anykernel/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument