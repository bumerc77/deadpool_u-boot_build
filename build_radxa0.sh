#!/bin/bash

./build.sh android-tv-13.0.0_r1 g12a_radxa0_v1

./generate-bins-new.sh fip-radxa0-20210802 out/u-boot/build/u-boot.bin

rm -rf out
