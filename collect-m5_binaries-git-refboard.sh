#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

<< "Description"
######################################################################
The goal of this script is gather all binaries provides by AML
in order to generate our final u-boot image from the u-boot.bin (bl33)

Some binaries come from the u-boot vendor
bl2.bin, bl30, bl31
######################################################################
Description

function usage() {
    echo "Usage: $0 [u-boot branch] [soc] [refboard] [power-up key]"
}

if [[ $# -lt 3 ]]
then
    usage
    exit 22
elif [[ $# -eq 3 ]]
then
    PWRKEYCODE=
else
    PWRKEYCODE=${4}
fi

GITBRANCH=${1}
SOCFAMILY=${2}
REFBOARD=${3}

if ! [[ "$SOCFAMILY" == "g12a" || "$SOCFAMILY" == "g12b" || "$SOCFAMILY" == "sm1" ]]
then
    echo "${SOCFAMILY} is not supported - should be [g12a, g12b, sm1]"
    usage
    exit 22
fi

if [[ "$SOCFAMILY" == "sm1" ]]
then
    SOCFAMILY="g12a"
fi

bl2="bl2/bin/$SOCFAMILY"
bl30="bl30/bin/$SOCFAMILY"
bl31="bl31/bl31_1.3/bin/$SOCFAMILY"
dir="bl33"
TMP="uboot-bins-$(date +%Y%m%d-%H%M%S)"

# path to clone the u-boot repos
TMP_GIT=$(mktemp -d)

# FIP-binaries
get_src () {
    local GITBRANCH="khadas-vims-v2015.01-5.15"
        git clone -n --depth=1 --filter=tree:0 --single-branch https://github.com/khadas/u-boot.git -b $GITBRANCH $TMP_GIT/FIP
        (
            cd $TMP_GIT/FIP
            git sparse-checkout set --no-cone /$bl2 /$bl30 /$bl31
            git checkout
        )
}

get_src "$@" || exit

# U-Boot
git clone --depth=1 https://github.com/bumerc77/u-boot_v2019.git -b $GITBRANCH $TMP_GIT/$dir
# Toolchains
mkdir $TMP_GIT/gcc-linaro_aarch64-elf
wget -qO- https://dl.khadas.com/products/vim4/tools/gcc-linaro-7.3.1-2018.05-i686-aarch64-elf.tar.xz | tar -xJ --strip-components=1 -C $TMP_GIT/gcc-linaro_aarch64-elf
mkdir $TMP_GIT/gcc-linaro-arm-none-eabi
wget -qO- https://mirror.twds.com.tw/armbian-dl/_toolchain/gcc-linaro-arm-none-eabi-4.8-2014.04_linux.tar.xz | tar -xJ --strip-components=1 -C $TMP_GIT/gcc-linaro-arm-none-eabi

sed -i "s,/opt/toolchains/gcc-linaro-.*/bin/,, " $TMP_GIT/$dir/Makefile

cp -r $TMP_GIT/FIP/$bl2 $TMP_GIT/$dir/bl2/bin/ && sync
cp -r $TMP_GIT/FIP/$bl30 $TMP_GIT/$dir/bl30/bin/ && sync
rm -rf $TMP_GIT/$dir/$bl31 && cp -r $TMP_GIT/FIP/$bl31 $TMP_GIT/$dir/$bl31 && sync

# custom power-up key
if ! [[ -z "$PWRKEYCODE" ]]
then
    board_cfg="$TMP_GIT/$dir/board/amlogic/configs/${REFBOARD}.h"
    head_tmp="$(mktemp $TMP_GIT/tmp.XXXX)"
    awk -v pwr_key=${4} '{if ($2=="CONFIG_IR_REMOTE_POWER_UP_KEY_VAL6") $3=pwr_key; print $0}' $board_cfg > $head_tmp
    cp $head_tmp $board_cfg
fi

(
    cd $TMP_GIT/$dir
    PATH=$TMP_GIT/gcc-linaro_aarch64-elf/bin:$TMP_GIT/gcc-linaro-arm-none-eabi/bin:$PATH CROSS_COMPILE=aarch64-elf- \
    ./mk ${REFBOARD} > /dev/null
)

mkdir $TMP
ln -sfn $TMP uboot-bins

cp $TMP_GIT/$dir/build/{u-boot.bin,u-boot.bin.sd.bin,u-boot.bin.usb.bl2,u-boot.bin.usb.tpl} $TMP/ && sync
dd if=$TMP/u-boot.bin of=$TMP/sd.img conv=fsync bs=512 seek=1

# Normalize
date > $TMP/info.txt
echo "BRANCH: $GITBRANCH ($(date +%Y%m%d))" >> $TMP/info.txt

if [[ "$SOCFAMILY" == "g12b" ]]
then
    dd if=$TMP_GIT/$dir/bl2/bin/$SOCFAMILY/bl2.bin of=$TMP_GIT/bl2_info.bin bs=$((0x1)) count=$((0x53)) skip=$((0xba90))
    echo "bl2: $(< "$TMP_GIT/bl2_info.bin")" >> $TMP/info.txt
    dd if=$TMP_GIT/$dir/bl30/bin/$SOCFAMILY/bl30.bin of=$TMP_GIT/bl30_info.bin bs=$((0x1)) count=$((0x40)) skip=$((0x76d7))
    echo "bl30: $(< "$TMP_GIT/bl30_info.bin")" >> $TMP/info.txt
    dd if=$TMP_GIT/$dir/bl31/bl31_1.3/bin/$SOCFAMILY/bl31.img of=$TMP_GIT/bl31_info.bin bs=$((0x1)) count=$((0x58)) skip=$((0x1e038))
    echo "bl31: $(< "$TMP_GIT/bl31_info.bin")" >> $TMP/info.txt
else
    dd if=$TMP_GIT/$dir/bl2/bin/$SOCFAMILY/bl2.bin of=$TMP_GIT/bl2_info.bin bs=$((0x1)) count=$((0x53)) skip=$((0xbdb8))
    echo "bl2: $(< "$TMP_GIT/bl2_info.bin")" >> $TMP/info.txt
    dd if=$TMP_GIT/$dir/bl30/bin/$SOCFAMILY/bl30.bin of=$TMP_GIT/bl30_info.bin bs=$((0x1)) count=$((0x40)) skip=$((0x7cf3))
    echo "bl30: $(< "$TMP_GIT/bl30_info.bin")" >> $TMP/info.txt
    dd if=$TMP_GIT/$dir/bl31/bl31_1.3/bin/$SOCFAMILY/bl31.img of=$TMP_GIT/bl31_info.bin bs=$((0x1)) count=$((0x58)) skip=$((0x1f078))
    echo "bl31: $(< "$TMP_GIT/bl31_info.bin")" >> $TMP/info.txt
fi

for component in $TMP_GIT/*
do
    if [[ -d $component/.git ]]
    then
        echo "$(basename $component): $(git --git-dir=$component/.git log --pretty=format:%H -1 HEAD)" >> $TMP/info.txt
    fi
done

if [[ "$REFBOARD" == "sm1_bananapi_m5" ]]
then
    dd if=$TMP_GIT/$dir/fip/$SOCFAMILY/aml_ddr.fw of=$TMP_GIT/fw_version.bin bs=$((0x1)) count=$((0x13)) skip=$((0xb28d))
    dd if=$TMP_GIT/$dir/fip/$SOCFAMILY/aml_ddr.fw of=$TMP_GIT/fw_built.bin bs=$((0x1)) count=$((0x46)) skip=$((0xadd8))
    sed -i "s/ :/:/" $TMP_GIT/fw_built.bin | echo "DDR-FIRMWARE: $(< "$TMP_GIT/fw_version.bin")" >> $TMP/info.txt
    echo "$(< "$TMP_GIT/fw_built.bin")" >> $TMP/info.txt
    SOCFAMILY="sm1"
fi

if [[ -n "$PWRKEYCODE" ]]
then
    echo "KEY-POWER: $4" >> $TMP/info.txt
fi

echo "SOC: $SOCFAMILY" >> $TMP/info.txt
echo "BOARD: $REFBOARD" >> $TMP/info.txt
rm -rf ${TMP_GIT}
