#!/bin/bash

./build.sh android-tv-10.0.0_r1 g12a_radxa0_v1

./generate-bins-new.sh fip-radxa02-220427 out/u-boot/build/u-boot.bin

rm -rf out
