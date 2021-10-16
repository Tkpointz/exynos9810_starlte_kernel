#! /bin/bash

DATE=$(TZ=GMT-8 date +"%Y%m%d-%H%M")

MODEL="Samsung galaxy S9 and S9 plus"

DEVICE="starlte_star2lte"

NAME="Sploitpay"

CHATID="-1001555864767"

KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

PROCS=$(nproc --all)

BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"

}

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

cloning() {
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 --depth=1 gcc64
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 --depth=1 gcc32
git clone https://github.com/Tkpointz/AnyKernel3.git -b starlte
git clone https://github.com/Tkpointz/sploitpay_kernel_modules.git modules

}

exports() {
export ANDROID_MAJOR_VERSION=q
export CROSS_COMPILE=gcc64/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=gcc32/bin/arm-linux-androideabi-
export KBUILD_BUILD_USER="Sploitpay"
export KBUILD_BUILD_HOST="Sploitpay.tk"

}

build_starlte() {
tg_post_msg "<b>Build Triggered</b>%0A<b>OS: </b><code>Arch Linux</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=GMT-8 date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler used: </b><code>GCC</code>%0A<b>Top Commit : </b><code>$COMMIT_HEAD</code>"
make ARCH=arm64 kali_starlte_defconfig
make ARCH=arm64 -j$PROCS

if [ -f arch/arm64/boot/Image ]
then
	echo "Starlte Kernel Successfully Compiled"
	mv arch/arm64/boot/Image AnyKernel3/starlte/Image
	mv arch/arm64/boot/dtb.img AnyKernel3/starlte/dtb.img
else
	echo "Starlte Kernel Compilation Failed!"
	tg_post_msg "<code>Starlte Kernel Compilation Failed</code>"
	exit

fi

}

build_star2lte() {
make clean && make mrproper
rm -rf arch/arm64/boot/dtb.img
git restore scripts/dtbtool_exynos/dtbtool
make ARCH=arm64 kali_star2lte_defconfig
make ARCH=arm64 -j$PROCS

if [ -f arch/arm64/boot/Image ]
then
        echo "Star2lte Kernel Successfully Compiled"
        mv arch/arm64/boot/Image AnyKernel3/star2lte/Image
        mv arch/arm64/boot/dtb.img AnyKernel3/star2lte/dtb.img
else
        echo "Star2lte Kernel Compilation Failed!"
        tg_post_msg "<code>Star2lte Kernel Compilation Failed</code>"
        exit

fi

}

generate_zip() {
#moving output files to flashable zip
mv drivers/staging/rtl8812au/88XXau.ko modules/system/lib/modules
mv drivers/staging/rtl8814au/8814au.ko modules/system/lib/modules
mv drivers/staging/rtl8188eus/8188eu.ko modules/system/lib/modules
#mv drivers/staging/rtl8821CU/8821cu.ko modules/system/lib/modules

cd AnyKernel3

zip -r "$NAME-$DEVICE-$DATE" . -x ".git*" -x "README.md" -x "*.zip" -x "*.jar"

ZIP_FINAL="$NAME-$DEVICE-$DATE"

}

zip_post() {
# post kernel zip file
tg_post_build "$ZIP_FINAL.zip" "$DATE"

# generating modules zip
cd ..
cd modules/
zip -r "$NAME-$DEVICE-Modules-$DATE" . -x ".git*" -x "README.md" -x "*.zip" -x "*.jar"
ZIP_MODULES="$NAME-$DEVICE-Modules-$DATE"

#post modules zip file
tg_post_build "$ZIP_MODULES.zip"

}

cloning
exports
build_starlte
build_star2lte
generate_zip
zip_post
