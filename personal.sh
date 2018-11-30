#!/bin/bash
cd ..

#	Let's compile this mess
#
#
mkdir -p out
export CROSS_COMPILE="$(pwd)/gcc8/bin/aarch64-opt-linux-android-"
export ARCH=arm64

#
#	Compile the Kernel for OxygenOS
#

#	START, END and DIFF variables to calculate rough total compilation time!

START=$(date +"%s")


#
#	Time for Custom Treble
#
make O=out ARCH=arm64 weebcustom_defconfig
make O=out -j16
END=$(date +"%s")
DIFF=$((END - START))

#	Preparing Kernel ZIP for Custom Treble ROMs


cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel/kernels/custom/
mkdir anykernel/kernels
mkdir anykernel/kernels/custom
cd $(pwd)/anykernel
#	We don't ned non treble anykernel
rm -rf nontreble.sh
mv treble.sh anykernel.sh

#	Name and push zip

ZIPNAME="WEEB_GCC_private.zip"
rm -rf WEEB_GCC_private.zip
zip -r9 $ZIPNAME * -x README.md $ZIPNAME
CHECKER=$(ls -l $ZIPNAME | awk '{print $5}')
if (($((CHECKER / 1048576)) > 5));
then
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="Compilation Time: <code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</code>
<i>Uploading....</i>" -d chat_id=$CHAT_ID -d parse_mode=HTML
	curl -F chat_id="$CHAT_ID" -F document=@"$(pwd)/$ZIPNAME" https://api.telegram.org/bot$BOT_API_KEY/sendDocument
else
	curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d text="The compiler decides to scream at @idkwhoiam322" -d chat_id=$CHAT_ID	
fi;
# Extra line here for OCD

# Oh there were 2 lines
# Oh 3
# Ok I'll stop here