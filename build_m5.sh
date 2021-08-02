#!/bin/bash

./build.sh android-tv-10.0.0_r1 g12a_odroidc4_v1

./generate-bins-new.sh fip-collect-g12a-odroidc4-odroidg12-v2015.01-20210623-153349 out/u-boot/build/u-boot.bin

rm -rf out
