# OBS Measurement Overlay Plugin

A native OBS Studio plugin that displays real-time measurement values from DMM (Digital Multimeter) and LCR (Inductance, Capacitance, Resistance) meters using the OpenTraceCapture library.

## Versioning

This project follows semantic versioning starting from version 0.1.0. The ABI (Application Binary Interface) is tied to the minor version number, meaning:

- **Major version** (0.x.x): Breaking API/ABI changes
- **Minor version** (x.1.x): ABI changes, new features  
- **Patch version** (x.x.1): Bug fixes, no ABI changes

Current version: **0.1.0**

## Features

- Real-time display of measurement values in OBS overlays
- Support for DMM and LCR devices via OpenTraceCapture
- Automatic unit detection (V, A, Ω, F, H, Hz)
- Semi-transparent background with customizable appearance
- Low-latency measurement updates

## Requirements

- OBS Studio (with development headers)
- OpenTraceCapture library
- Meson >= 0.60.0
- Ninja build system
- GCC/Clang with C++17 support
- pkg-config

## Building

1. **Set up OBS development headers:**
   
   On most systems, you'll need to clone the OBS Studio source for headers:
   ```bash
   git clone https://github.com/obsproject/obs-studio.git
   export OBS_INCLUDE_DIR=$(pwd)/obs-studio/libobs
   ```
   
   Alternatively, if your system has OBS development packages:
   ```bash
   # Ubuntu/Debian
   sudo apt install libobs-dev
   
   # In this case, no OBS_INCLUDE_DIR needed
   ```

2. **Build and install OpenTraceCapture dependency:**
   ```bash
   git clone https://github.com/opentracelab/OpenTraceCapture.git
   cd OpenTraceCapture
   meson setup build --buildtype=release
   meson compile -C build
   meson install -C build  # or sudo meson install -C build
   cd ..
   ```

3. **Build the plugin:**
   ```bash
   meson setup build --buildtype=release
   meson compile -C build
   ```

4. **Install the plugin:**
   ```bash
   meson install -C build  # or sudo meson install -C build
   ```

## Usage

1. Start OBS Studio
2. Add a new Source → "Measurement Overlay"
3. Connect your DMM/LCR device
4. The overlay will automatically detect and display measurements

## Supported Devices

Any device supported by OpenTraceCapture, including:
- Keysight/Agilent multimeters
- Fluke multimeters
- Rigol multimeters
- LCR meters with serial/USB interfaces

## Configuration

The plugin automatically scans for available devices. Measurements are updated at 10Hz for smooth real-time display.

## Troubleshooting

- Ensure your measurement device is connected and recognized by the system
- Check that OpenTraceCapture can detect your device using `opentrace-cli --scan`
- Verify OBS Studio can load the plugin by checking the log files
