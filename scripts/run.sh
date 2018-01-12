#!/bin/bash

cd /pastec2
mkdir -p build data
cd build
#cmake ..
make && ./pastec -p 4212 /pastec/data/visualWordsORB.dat