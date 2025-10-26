# OBS Measurement Overlay

An OBS Studio plugin that displays real-time measurements from DMM (Digital Multimeter) and LCR meter devices as an overlay in your stream or recording.

## Features

- Real-time measurement display from USB/serial measurement devices
- Auto-detection of connected devices
- Manual configuration for serial port devices
- Customizable display (size, precision, units)
- Support for voltage, current, resistance, capacitance, inductance, and frequency measurements

## Building

### Prerequisites

**Ubuntu/Debian:**
```bash
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt-get update
sudo apt-get install obs-studio libsimde-dev meson ninja-build pkg-config \
  libglib2.0-dev libusb-1.0-0-dev libzip-dev libftdi1-dev \
  libserialport-dev libhidapi-dev
```

**Install OpenTraceCapture:**
```bash
# Download latest release from https://github.com/OpenTraceLab/OpenTraceCapture/releases
wget https://github.com/OpenTraceLab/OpenTraceCapture/releases/download/v0.1.2-alpha.12/opentracecapture-linux.tar.gz
sudo tar -xzf opentracecapture-linux.tar.gz -C /usr/local
```

### Build Steps

```bash
meson setup build --buildtype=release
ninja -C build
sudo ninja -C build install
```

## Usage

1. Launch OBS Studio
2. Add a new source → "Measurement Overlay"
3. Configure your device:
   - **Auto-detect**: Select from dropdown of detected devices
   - **Manual**: Specify driver, connection (e.g., `/dev/ttyUSB0`), and serial config (e.g., `9600/8n1`)
4. Adjust display settings (width, height, font size, precision)

## Supported Devices

Any device supported by OpenTraceCapture, including:
- USB DMMs (Keysight, Rigol, Siglent, etc.)
- Serial port DMMs (with manual configuration)
- LCR meters
- See [OpenTraceCapture documentation](https://github.com/OpenTraceLab/OpenTraceCapture) for full list

## Development

Based on [obs-plugintemplate](https://github.com/obsproject/obs-plugintemplate) structure with modern OBS 30+ API.

## License

GPL-2.0 - See COPYING file

## Community

Discord: https://discord.gg/DsYwx59MPh
