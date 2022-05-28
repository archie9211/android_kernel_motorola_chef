KERNEL_DIR=$PWD
ZIPNAME="DarkOne-v4.0"

# The name of the device for which the kernel is built
MODEL="Motorola One Power"

# The codename of the device
DEVICE="chef"

# The defconfig which should be used. Get it from config.gz from
# your device or check source
DEFCONFIG=chef_defconfig

# Clean source prior building. 1 is NO(default) | 0 is YES
INCREMENTAL=0

# Push ZIP to Telegram. 1 is YES | 0 is NO(default)

# CHATID="-1001113679979" my channel
CHATID="-1001757331205" # Chef Group

COMMIT_HEAD=$(git log --oneline -1)

# Set Date 
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")

function exports {
	export KBUILD_BUILD_USER="archie9211"
	export KBUILD_BUILD_HOST="codespaces"
	export ARCH=arm64
	export SUBARCH=arm64
	export BRANCH=$(git symbolic-ref --short -q HEAD)
    TC_DIR=$PWD/../myscripts/clang
	KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	export KBUILD_COMPILER_STRING
	PATH=$TC_DIR/bin/:$PATH
	export CROSS_COMPILE="$PWD/../myscripts/gcc/bin/aarch64-linux-gnu-"
	export PATH
	export BOT_MSG_URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
	export PROCS=$(nproc --all)
}
function tg_post_msg {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##----------------------------------------------------------------##

function tg_post_build {
	curl --progress-bar -F document=@"$1" $BOT_BUILD_URL \
	-F chat_id="$2"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"  
}

##----------------------------------------------------------##

function build_kernel {

	tg_post_msg "TEST TEST TEST TEST %0A<b>$CIRCLE_BUILD_NUM CI Build Triggered</b>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>CircleCI</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$BRANCH</code>%0A<b>Top Commit : </b><code>$COMMIT_HEAD</code>%0A<b>Status : </b>#Nightly" "$CHATID"


	make O=out $DEFCONFIG

	BUILD_START=$(date +"%s")
	make -j$PROCS O=out \
		CROSS_COMPILE=$CROSS_COMPILE \
		CC=clang  
		2>&1 | tee error.log
	
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	check_img
}

##-------------------------------------------------------------##

function check_img {
	if [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ] 
	    then
		gen_zip
	else		
		tg_post_build error.log "$CHNLID" "<b>Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
	fi
}

##--------------------------------------------------------------##

function gen_zip {
	mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ../myscripts/AnyKernel2/Image.gz-dtb
	cd ../myscripts/AnyKernel2
    rm -rf *.zip
	zip -r9 $ZIPNAME-$DEVICE-$DATE.zip * -x .git README.md	
	MD5CHECK=$(md5sum $ZIPNAME-$DEVICE-$DATE.zip | cut -d' ' -f1)	
	tg_post_build $ZIPNAME-$DEVICE-$DATE.zip "$CHATID" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s) | MD5 Checksum : <code>$MD5CHECK</code>"
	cd ..
}


exports
build_kernel

