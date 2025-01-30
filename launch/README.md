# Samurai Babel Launcher for ioquake3

## Overview
The Samurai Babel Launcher is an innovative take on the ioquake3 launcher, designed with modern gaming needs in mind. Developed with QT and written in C++, this launcher aims to streamline updates, enhance user accessibility, and support multiple operating systems for ioquake3 and compatible games.

## Vision
This project seeks to unify the ioquake3 experience by:
- Providing a seamless update system across Windows, macOS, and Linux.
- Making ioquake3’s advanced features easily accessible to players.
- Supporting standalone mods and encapsulated games with integrated update mechanisms.
- Enabling advanced functionality like configuration management, server browsing, and mod preloading.

---

## Features and Roadmap

### Required Features

#### Version 0.1 (Alpha)
- [x] Launch the ioquake3 program.
- [x] Launch ioquake3 at different resolutions.
- [ ] Download and install patches for Quake 3.
- [ ] Display EULA before downloading patches.

#### Version 0.5 (Beta)
- [ ] Download and install ioquake3.
- [ ] Copy Quake 3 data from a retail CD.
- [ ] Update ioquake3.
- [ ] Self-update capability.
- [ ] Initial support for other operating systems (Linux support started).

#### Version 1.0
- [ ] Configure launch options.
- [ ] Configure player options.
- [ ] WYSIWYG name configuration.
- [ ] Integration with Steam and GOG versions of Quake 3.
- [ ] Backup, save, and swap configurations.
- [ ] Full support for Linux, Windows, and macOS.

#### Version 2.0
- [ ] Support for additional games (e.g., Tremulous, Smokin' Guns, Turtle Arena).
- [ ] Automated mod switching.
- [ ] Built-in server browser.
- [ ] Integrated news feed.
- [ ] LAN support.
- [ ] Preload mods, maps, and content via internet protocols.
- [ ] URI integration (e.g., `q3://`, `trem://`, `ioq3://`).
- [ ] RCON interface for remote server management.

---

## Building the Launcher

### Prerequisites
- **Qt Framework**: Ensure QT is installed for your platform.
- **C++ Compiler**: Use GCC, Clang, or MSVC as appropriate for your OS.
- **Git**: Clone the repository.

### Instructions
1. **Clone the Repository**
   ```bash
   git clone https://github.com/ringsce/samurai_babel_launcher.git
   cd samurai_babel_launcher
   ```

2. **Build the Project**
   - **On Linux/MacOS**:
     ```bash
     qmake
     make
     ```
   - **On Windows**:
     ```cmd
     qmake
     nmake
     ```

3. **Run the Launcher**
   Execute the built binary from the `build/` directory.

---

## Advanced Goals
- **Inspired by Samurai Babel**:
  The launcher incorporates concepts from the *Samurai Babel* framework, focusing on modularity and cross-platform compatibility.

- **Future Expansion**:
  The Samurai Babel Launcher will evolve to support new games and features, ensuring it remains a vital tool for ioquake3 and beyond.

---

For further details and updates, visit the [official GitHub repository](https://github.com/ringsce/samurai_babel_launcher).

