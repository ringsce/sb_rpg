# Valkyrie Engine - Build Instructions

Cross-platform game engine with support for macOS, Linux Desktop, and Anbernic handheld consoles.

## Prerequisites

### All Platforms
- C++17 compatible compiler
- CMake 3.16+ or Qt Creator with qmake
- SDL2 and SDL2_image
- Qt6 (for desktop builds)

### macOS
```bash
brew install sdl2 sdl2_image qt@6 molten-vk curl
```

### Linux Desktop
```bash
# Ubuntu/Debian
sudo apt install build-essential cmake qt6-base-dev libsdl2-dev libsdl2-image-dev libvulkan-dev libcurl4-openssl-dev

# Fedora
sudo dnf install gcc-c++ cmake qt6-qtbase-devel SDL2-devel SDL2_image-devel vulkan-devel libcurl-devel

# Arch
sudo pacman -S base-devel cmake qt6-base sdl2 sdl2_image vulkan-icd-loader curl
```

### Anbernic Devices
Cross-compile or build directly on device with ArkOS/JELOS development tools.

## Building with CMake

### macOS (with Qt6)
```bash
mkdir build && cd build
cmake -DUSE_QT6=ON -DUSE_SDL3=OFF ..
make -j$(sysctl -n hw.ncpu)
./Valkyrie.app/Contents/MacOS/Valkyrie
```

### macOS (without Qt6 - standalone SDL)
```bash
mkdir build && cd build
cmake -DUSE_QT6=OFF -DUSE_SDL3=OFF ..
make -j$(sysctl -n hw.ncpu)
./Valkyrie
```

### Linux Desktop (with Qt6)
```bash
mkdir build && cd build
cmake -DUSE_QT6=ON -DUSE_SDL3=OFF ..
make -j$(nproc)
./Valkyrie
```

### Anbernic (cross-compile)
```bash
mkdir build && cd build
cmake -DUSE_QT6=OFF \
      -DUSE_SDL3=OFF \
      -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
      -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
      -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
      ..
make -j$(nproc)

# Install to microSD card
sudo make install DESTDIR=/path/to/sdcard
```

### Anbernic (on-device build)
```bash
mkdir build && cd build
cmake -DUSE_QT6=OFF -DUSE_SDL3=OFF ..
make -j4
sudo make install  # Installs to /roms/ports
```

## Building with Qt Creator

1. Open `Valkyrie.pro` in Qt Creator
2. Configure project for your kit (Desktop Qt 6.x)
3. Build → Build Project "Valkyrie"
4. Run → Run

### Qt Creator Platform-Specific Notes

**macOS:**
- Automatically detects Homebrew SDL2 installation
- Creates app bundle in `build/release/Valkyrie.app`

**Linux Desktop:**
- Uses pkg-config to find SDL2
- Output binary: `build/release/Valkyrie`

**Anbernic:**
- Detects ARM64 architecture
- Optimizes for Cortex-A55
- Creates install target for `/roms/ports`

## CMake Build Options

| Option | Default | Description |
|--------|---------|-------------|
| `USE_QT6` | ON | Enable Qt6 GUI framework |
| `USE_SDL3` | OFF | Use SDL3 instead of SDL2 |
| `USE_MoltenVK` | ON (macOS) | Use MoltenVK for Vulkan |
| `USE_KCC` | OFF | Enable Kayte C Compiler for scripts |
| `STANDALONE` | ON | Skip base/ folder, use content/ |

Example with options:
```bash
cmake -DUSE_QT6=ON -DUSE_MoltenVK=ON -DUSE_KCC=OFF ..
```

## Platform Detection

The engine automatically detects:
- **macOS**: Apple Silicon (arm64) or Intel (x86_64)
- **Linux Desktop**: x86_64 architecture
- **Anbernic**: ARM64 with device-specific configurations
  - RG353 series (P/V/M/PS)
  - RG405 series (M/V)
  - RG503, RG552
  - RG35XX series
  - And more...

## Directory Structure

```
Valkyrie/
├── build/              # Build output
├── src/               # Source files
│   ├── ai.cpp
│   ├── api.cpp
│   ├── gamepad.cpp
│   ├── AnbernicConfig.cpp
│   ├── SDLWidget.cpp
│   └── MainWindow.cpp
├── srv/               # Server components
├── assets/            # Game assets (optional)
├── res/               # Resources (optional)
├── main.cpp           # Main entry point
├── game_utils.cpp     # Utility functions
├── CMakeLists.txt     # CMake build file
├── Valkyrie.pro       # Qt Creator project
├── Info.plist         # macOS bundle info
└── SamuraiBabel.png   # Splash screen
```

## Installing on Anbernic

### Method 1: Via Install Script
```bash
./copy_to_anbernic.sh /media/roms/ports
```

### Method 2: Manual Installation
```bash
# Copy executable
cp build/Valkyrie /path/to/sdcard/roms/ports/

# Copy launch script
cp valkyrie_launch.sh /path/to/sdcard/roms/ports/
chmod +x /path/to/sdcard/roms/ports/valkyrie_launch.sh

# Copy assets
cp SamuraiBabel.png /path/to/sdcard/roms/ports/
```

### Method 3: CMake Install
```bash
cd build
sudo make install  # Installs to /roms/ports
```

## Troubleshooting

### macOS: "Developer cannot be verified"
```bash
xattr -cr Valkyrie.app
codesign --force --deep --sign - Valkyrie.app
```

### Linux: SDL2 not found
```bash
# Verify SDL2 installation
pkg-config --modversion sdl2
pkg-config --cflags --libs sdl2

# If not found, install:
sudo apt install libsdl2-dev libsdl2-image-dev
```

### Anbernic: Black screen on startup
1. Check file permissions: `chmod +x Valkyrie`
2. Verify assets are copied: `ls -la /roms/ports/SamuraiBabel.png`
3. Check logs in `/tmp/` or use the launch script

### Qt6 not found
```bash
# macOS
brew install qt@6
export Qt6_DIR=/opt/homebrew/opt/qt@6

# Linux
sudo apt install qt6-base-dev qt6-base-dev-tools
```

## Running the Game

### macOS
```bash
# App bundle
open build/Valkyrie.app

# Or directly
./build/Valkyrie.app/Contents/MacOS/Valkyrie
```

### Linux Desktop
```bash
./build/Valkyrie
```

### Anbernic
Navigate to **Ports** section in your CFW menu and select **Valkyrie**.

## Controls

### Keyboard (Desktop)
- **ESC**: Quit
- **Enter**: Confirm
- **Arrow Keys**: Navigation

### Gamepad (Anbernic)
- **START**: Quit application
- **SELECT**: Menu
- **A/B**: Confirm/Cancel
- **D-Pad**: Navigation
- **Analog Sticks**: Camera/Movement (on supported devices)

## Development

### Debug Build
```bash
mkdir build-debug && cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug ..
make
```

### Enable Verbose Logging
Add to CMakeLists.txt:
```cmake
add_definitions(-DDEBUG_LOGGING)
```

### Cross-platform Testing
Test on all platforms before release:
1. macOS (Apple Silicon)
2. macOS (Intel)
3. Linux Desktop
4. Anbernic device or emulator

## Additional Resources

- [SDL2 Documentation](https://wiki.libsdl.org/)
- [Qt6 Documentation](https://doc.qt.io/qt-6/)
- [Anbernic Wiki](https://github.com/christianhaitian/arkos/wiki)
- [MoltenVK Guide](https://github.com/KhronosGroup/MoltenVK)

## License

See LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues
- Discord Server (if available)
- Email support

---

**Built with ❤️ for cross-platform gaming**
