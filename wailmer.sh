#!/bin/bash
shopt -s expand_aliases

wget https://raw.githubusercontent.com/TraceEntertains/wailmer/main/spheal-core.sh
chmod +x ./spheal-core.sh
./spheal-core.sh

git clone https://github.com/fortheusers/hb-appstore --recursive
cd hb-appstore
make ${PLATFORM}

echo Build attempted, if failed, please try to resolve errors and run "make $PLATFORM" again.
