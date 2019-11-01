export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="archie"
export KBUILD_BUILD_HOST="Hackintosh"
make chef_defconfig O=out/
export KBUILD_COMPILER_STRING=$(../clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
make -j8  \
                      ARCH=arm64 \
                      CC=../clang/bin/clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=/home/archie/work/aarch64-linux-android-4.9/bin/aarch64-linux-android-

