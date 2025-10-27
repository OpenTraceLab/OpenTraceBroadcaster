#!/bin/bash

# Build script for OBS Measurement Overlay Plugin

set -e

# Setup build directory with CMake
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build with CMake
cmake --build build --parallel

echo "Build complete. Plugin built in: build/"
echo "Then restart OBS Studio and look for 'Measurement Overlay' in Sources."
