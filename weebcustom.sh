#!/bin/bash
cd ..

export KBUILD_COMPILER_STRING="$($(pwd)/clang/clang-r328903/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')";
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Build started for branch $(git rev-parse --abbrev-ref HEAD) using Clang 7.0.2!
Latest Commits:
$(git log --pretty=format:'%h : %s' -{1..5})" -d chat_id=$CHAT_ID
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

#	START, END and DIFF variables to calculate rough total compilation time!

START=$(date +"%s")

#	Date and Time
export BUILDDATE=$(date +%Y%m%d)
export BUILDTIME=$(date +%H%M)

#	Log
export LOGFILE=log-$BUILDDATE-$BUILDTIME.txt

make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r328903/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-"	| tee $LOGFILE

#	Failure
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Senpai, I hate to tell you but... git commit die!
Here's logs in case building for Non Treble ROMs miserably!
Check log file $LOGFILE" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$LOGFILE" https://api.telegram.org/bot$BOT_API_KEY/sendDocument



END=$(date +"%s")
DIFF=$((END - START))

#	Success
#	Preparing Kernel ZIP
mkdir anykernel/kernels
mkdir anykernel/kernels/custom
cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/


#	ReZIP the Kernel
cd $(pwd)/anykernel
rm -rf treble.sh
mv nontreble.sh anykernel.sh
ZIPNAME="WeebKerneL-NonTreble_V1.12.zip"
zip -r9 $ZIPNAME * -x README.md $ZIPNAME

#	Time to push the Kernel ZIP
cd ..
curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Weebu Karuneru bureedo successu Oniisama!
The build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds to compile successfully!!
Uploading Kernel zip file here now!! 
	~(^.^)~" -d chat_id=$CHAT_ID
curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/anykernel/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument