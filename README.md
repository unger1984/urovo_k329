# Urovo K329 — macOS Print Driver

CUPS driver for the Urovo K329 thermal label printer, enabling PDF printing from any macOS application via the standard print dialog.

> **[Русская версия / Russian version](README.rus.md)**

## Table of Contents

- [How It Works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Uninstallation](#uninstallation)
- [Printing](#printing)
- [Printer Setup](#printer-setup)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)

## How It Works

The Urovo K329 firmware does not support standard graphics commands (ZPL ^GFA, TSPL BITMAP, CPCL EG) over USB on macOS. This driver works around the limitation:

1. CUPS receives a PDF and passes it to the backend
2. Backend saves the PDF to the spool directory `/var/spool/urovo329/`
3. A launchd daemon detects the file and launches the helper
4. Helper rasterizes the PDF via Ghostscript (203 DPI, monochrome)
5. Converts the raster to a TSPL2 BITMAP command
6. Sends the data to the printer via USB in 64-byte chunks (K329 firmware requirement)

## Requirements

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh)
- Ghostscript: `brew install ghostscript`
- libusb: `brew install libusb`
- Python 3 (built into macOS)
- pyusb: installed automatically during driver setup

## Installation

### One-liner (no clone needed)

```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/urovo_k329/main/install-remote.sh | bash
```

### From repository

```bash
git clone https://github.com/unger1984/urovo_k329.git
cd urovo/driver
./install.sh
```

The script will:
- Check and install dependencies (pyusb)
- Copy backend, filter, helper, and PPD files
- Configure the launchd daemon
- Add the printer to CUPS

After installation, the **Urovo_K329** printer will appear in System Settings.

## Uninstallation

```bash
# Local
./uninstall.sh

# Remote
curl -fsSL https://raw.githubusercontent.com/unger1984/urovo_k329/main/uninstall-remote.sh | bash
```

Completely removes all driver components.

## Printing

Print from any application using the standard print dialog — select **Urovo_K329** as the printer.

### Supported Label Sizes

| Size         | PPD Name   |
|-------------|------------|
| 40 × 30 mm  | w113h85    |
| 50 × 40 mm  | w142h113   |
| 55 × 39 mm  | w156h110 (default) |
| 58 × 40 mm  | w164h113   |
| 60 × 40 mm  | w170h113   |
| 80 × 50 mm  | w227h142   |
| 80 × 60 mm  | w227h170   |
| Custom       | Custom     |

### Command Line Printing

```bash
# Via CUPS
lp -d Urovo_K329 file.pdf

# Direct (bypassing CUPS)
urovo-print-helper file.pdf [copies]
```

## Printer Setup

The printer must be in **TSPL** mode (switch via printer menu: Settings → Command → TSPL).

### Print Area Calibration

Print area parameters are configured in `/usr/local/bin/urovo-print-helper`:

```python
WIDTH = 420      # width in dots (203 DPI, ~52 mm)
HEIGHT = 260     # height in dots (~32 mm)
Y_OFFSET = 16    # top offset in dots (~2 mm)
```

Adjust these values to match your labels.

## Project Structure

```
driver/
├── install.sh              — installer
├── uninstall.sh            — uninstaller
├── urovo-k329              — CUPS filter (passes PDF to backend)
├── urovo-k329-backend      — CUPS backend (spool + waits for helper)
├── urovo-print-helper      — PDF→TSPL2 conversion and USB delivery
├── Urovo-K329.ppd          — printer description for CUPS
└── com.urovo.k329.printer.plist — launchd daemon (watches spool)
```

## Troubleshooting

### Printer does not print
1. Verify the printer is in TSPL mode
2. Reconnect the USB cable
3. Check the log: `cat /tmp/urovo-print-helper.log`
4. Check CUPS log: `tail -50 /var/log/cups/error_log | grep urovo`

### Job stuck in queue
```bash
sudo cupsenable Urovo_K329
```

### Reinstall
```bash
./uninstall.sh && ./install.sh
```

## Technical Details

- **Protocol**: TSPL2 (`BITMAP x,y,width_bytes,height,mode,data` command)
- **Connection**: USB (VID=0x1fc9, PID=0x009b, CODEK PRINTER)
- **Transfer**: 64-byte chunks with 50ms pause every 1024 bytes
- **Rasterization**: Ghostscript, 203 DPI, monochrome PBM
- **Printer DPI**: 203 (8 dots/mm)
