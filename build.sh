#!/bin/bash

# Detect Homebrew
if brew --version > /dev/null 2>&1; then
    echo "Homebrew detected."
else
    echo "No Homebrew detected. Installing Homebrew..."
    # Install Homebrew (optional)
    if ! dpkg -s brew &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y libssl-dev libffi-dev libbz2-dev zlib1g-dev build-essential git libreadline-gp-dev libncurses5-dev libgdbm-dev libstdc++6-dev libicu-dev libxml2-dev libx11-dev libxmu-dev
    fi
fi

# Install SDL2 and QT5
if ! which sdl2 &> /dev/null; then
    echo "Installing SDL2..."
    brew install sdl2
fi

if ! which qt5 &> /dev/null; then
    echo "Installing Qt5..."
    brew install qt5
fi

# Install iOS SDKs (optional)
if ! which xcode &> /dev/null; then
    echo "Installing Xcode (not found). Installing Xcode instead..."
    # Install Xcode
    brew install xcode --options $(brew --prefix)/usr/local/bin/xcode
fi

# Install Android SDKs (optional)
if ! which android-sdk &> /dev/null; then
    echo "Installing Android SDK (not found). Installing Android SDK instead..."
    # Install Android SDK
    brew install android-sdk --version=10.0.1 --options $(brew --prefix)/usr/local/bin/android-sdk
fi

# Compile a C project using GCC
if ! which gcc &> /dev/null; then
    echo "Compiling with GCC (not found). Compiling with g++ instead..."
    g++
else
    echo "Using GCC. Compiling..."
fi

# Other dependencies
echo "Installing other dependencies:"
echo "  - libssl-dev (for SSL/TLS support)"
if ! which openssl &> /dev/null; then
    brew install openssl --version=1.0.1 --options $(brew --prefix)/usr/local/bin/openssl
fi
echo "  - libffi-dev (for internationalization and locale support)"
if ! which libffi &> /dev/null; then
    brew install libffi --version=2.3 --options $(brew --prefix)/usr/local/lib/libffi.dylib
fi

echo "All dependencies installed. Compilation started..."
