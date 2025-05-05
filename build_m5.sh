#!/bin/bash

if [ "${FORCE_RECOVERY}" == "true" ]
then
./collect-m5_binaries-git-refboard.sh android-tv-13.0.0_r1-recovery-only sm1 sm1_bananapim5_v1
elif [ "${CONSOLE_ENABLED}" == "true" ]
then
./collect-m5_binaries-git-refboard.sh android-tv-13.0.0_r1-console sm1 sm1_bananapim5_v1
else
./collect-m5_binaries-git-refboard.sh android-tv-13.0.0_r1 sm1 sm1_bananapim5_v1
fi
