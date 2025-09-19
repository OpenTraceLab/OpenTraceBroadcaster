#!/bin/bash

# Build script for OBS Measurement Overlay Plugin

set -e

# Setup build directory with Meson
meson setup builddir --buildtype=release

# Build with Ninja
meson compile -C builddir

echo "Build complete. To install, run: meson install -C builddir"
echo "Then restart OBS Studio and look for 'Measurement Overlay' in Sources."
