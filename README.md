# OBS Measurement Overlay Plugin

A native OBS Studio plugin that displays real-time measurement values from DMM (Digital Multimeter) and LCR (Inductance, Capacitance, Resistance) meters using the OpenTraceCapture library.

## Features

- Real-time display of measurement values in OBS overlays
- Support for DMM and LCR devices via OpenTraceCapture
- Automatic unit detection (V, A, Ω, F, H, Hz)
- Semi-transparent background with customizable appearance
- Low-latency measurement updates

## Requirements

- OBS Studio (with development headers)
- OpenTraceCapture library (from ../OpenTraceCapture)
- Meson >= 0.60.0
- Ninja build system
- GCC/Clang with C++17 support
- pkg-config

## Building

1. Ensure OpenTraceCapture is built and installed:
   ```bash
   cd ../OpenTraceCapture
   meson setup builddir
   meson compile -C builddir
   meson install -C builddir
   ```

2. Build the plugin:
   ```bash
   ./build.sh
   ```

3. Install the plugin:
   ```bash
   meson install -C builddir
   ```

## Usage

1. Start OBS Studio
2. Add a new Source → "Measurement Overlay"
3. Connect your DMM/LCR device
4. The overlay will automatically detect and display measurements

## Supported Devices

Any device supported by OpenTraceCapture/libsigrok, including:
- Keysight/Agilent multimeters
- Fluke multimeters
- Rigol multimeters
- LCR meters with serial/USB interfaces

## Configuration

The plugin automatically scans for available devices. Measurements are updated at 10Hz for smooth real-time display.

## Troubleshooting

- Ensure your measurement device is connected and recognized by the system
- Check that OpenTraceCapture can detect your device using `sigrok-cli --scan`
- Verify OBS Studio can load the plugin by checking the log files
