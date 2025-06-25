#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0
KERNEL_DIR="$(pwd)"
GC_DIR="$HOME/toolchains/neutron-clang"
AK3_DIR="$HOME/AnyKernel3"
MKDTBO_FILE="$KERNEL_DIR/mkdtboimg.py"
DEFCONFIG="vendor/xiaomi-qgki_defconfig vendor/debugfs.config"
REDWOOD_DEF="vendor/redwood-fragment.config"

export PATH="${GC_DIR}/bin:/usr/bin:${PATH}"

  if ! [ -d "$GC_DIR" ]; then
    if ! git clone -b master --depth=1 https://gitlab.com/NotZeetaa/aosp-clang-17.0.0 $GC_DIR; then
    echo "Cloning failed! Aborting..."
    exit 1
    fi
  fi

if ! [ -d "$AK3_DIR" ]; then
echo "Anykernel 3 not found! Cloning to $AK3_DIR..."
if ! git clone https://github.com/anothernewbieUwU/AnyKernel3.git $AK3_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -f "$MKDTBO_FILE" ]; then
echo "Mkdtboimg not found! Wget to $MKDTBO_FILE..."
if ! wget https://raw.githubusercontent.com/awakened1712/android_kernel_oneplus_sm8350/lineage-21/mkdtboimg.py $KERNEL_DIR; then
echo "Wget failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=Bakskutz
export KBUILD_BUILD_HOST=Lab

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG \
                  $REDWOOD_DEF

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 LLVM=1 Image dtbs

if [ -f "out/arch/arm64/boot/Image" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
fi

cd $AK3_DIR
make clean
cp $KERNEL_DIR/out/arch/arm64/boot/Image $AK3_DIR
find $KERNEL_DIR/out/arch/arm64/boot/dts/vendor -name '*.dtb' -exec cat {} + > $AK3_DIR/dtb;
python3 $KERNEL_DIR/mkdtboimg.py create $AK3_DIR/dtbo.img $KERNEL_DIR/out/arch/arm64/boot/dts/vendor/qcom/*.dtbo
make
cd $KERNEL_DIR
rm -rf out/arch/arm64/boot