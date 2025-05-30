#!/bin/bash

# Exit on any error
set -e

# Get absolute path to the sb_rpg root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../sb_rpg" && pwd)"

# Setup build directory inside sb_rpg
BUILD_DIR="$ROOT_DIR/xcode-tvos-release"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Determine OpenAL-soft path if not already set
if [ -z "$OPENAL_PREFIX" ]; then
  OPENAL_PREFIX=$(brew --prefix openal-soft 2>/dev/null || true)
  if [ -z "$OPENAL_PREFIX" ]; then
    echo "Warning: openal-soft not found via Homebrew."
    echo "Proceeding without OpenAL. You may set OPENAL_PREFIX manually."
  else
    echo "Using OpenAL from: $OPENAL_PREFIX"
  fi
fi

# Toolchain path for ios-cmake (assumed relative to sb_rpg)
TVOS_TOOLCHAIN="$ROOT_DIR/cmake/ios-cmake/ios.toolchain.cmake"

# Run CMake for tvOS using Xcode generator
cmake -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE="$TVOS_TOOLCHAIN" \
  -DPLATFORM=TVOS \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CONFIGURATION_TYPES="Release;MinSizeRel;RelWithDebInfo" \
  -DMACOSX_BUNDLE=ON \
  -DFFMPEG=OFF \
  -DBINKDEC=ON \
  -DUSE_MoltenVK=ON \
  -DUSE_METAL2=OFF \
  -DOPENAL=$([ -n "$OPENAL_PREFIX" ] && echo ON || echo OFF) \
  ${OPENAL_PREFIX:+-DOPENAL_LIBRARY="$OPENAL_PREFIX/lib/libopenal.dylib"} \
  ${OPENAL_PREFIX:+-DOPENAL_INCLUDE_DIR="$OPENAL_PREFIX/include"} \
  -DCMAKE_XCODE_GENERATE_SCHEME=ON \
  -DCMAKE_XCODE_SCHEME_ENVIRONMENT="OS_ACTIVITY_MODE=disable" \
  -DCMAKE_XCODE_SCHEME_ENABLE_GPU_API_VALIDATION=OFF \
  -DCMAKE_POLICY_DEFAULT_CMP0142=NEW \
  -Wno-dev "$ROOT_DIR"

echo "✅ Valkyrie tvOS Xcode project generated in: $BUILD_DIR"
