#!/bin/bash

if [ "${FORCE_RECOVERY}" == "true" ]
then
./build.sh android-tv-13.0.0_r1-recovery-only g12a_bananapim5_v1
elif [ "${CONSOLE_ENABLED}" == "true" ]
then
./build.sh android-tv-13.0.0_r1-console g12a_bananapim5_v1
else
./build.sh android-tv-13.0.0_r1 g12a_bananapim5_v1
fi

./generate-bins-new.sh fip-collect-g12a-odroidc4-odroidg12-v2015.01-20210623-153349 out/u-boot/build/u-boot.bin

rm -rf out
