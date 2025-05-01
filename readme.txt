collect FIP binaries:

./collect-c4_binaries-git-refboard.sh odroidg12-v2015.01 sm1 odroidc4

build u-boot:
./build.sh android-tv-10.0.0_r1 g12a_odroidc4_v1

generate fip binary:
./generate-bins-new.sh fip-collect-g12a-odroidc4-odroidg12-v2015.01-20210623-153349 out/u-boot/build/u-boot.bin

# Bananapi M5
collect FIP & build u-boot:

./collect-m5_binaries-git-refboard.sh android-tv-13.0.0_r1 sm1 sm1_bananapim5_v1


scripts originally from https://android.googlesource.com/device/amlogic/yukawa/+/refs/heads/master/bootloader/scripts/
