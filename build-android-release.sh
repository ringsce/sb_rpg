#!/bin/bash

cd ..
rm -rf android-release
mkdir android-release
cd android-release

# Path to Android NDK (modify if your NDK is in a different location)
if [ -z "$ANDROID_NDK_HOME" ]; then
  export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk-bundle
  if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME is not set or points to an invalid path."
    exit 1
  fi
fi

# Determine OpenAL-soft path (optional)
if [ -z "$OPENAL_PREFIX" ]; then
  OPENAL_PREFIX=$(brew --prefix openal-soft 2>/dev/null)
  if [ -z "$OPENAL_PREFIX" ]; then
    echo "Warning: openal-soft is not installed via Homebrew."
    echo "Proceeding without OpenAL. Define OPENAL_PREFIX manually if needed."
  fi
fi

# Android ABI and platform (customize as needed)
ANDROID_ABI="arm64-v8a"
ANDROID_PLATFORM="android-24"

cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=$ANDROID_ABI \
  -DANDROID_PLATFORM=$ANDROID_PLATFORM \
  -DCMAKE_BUILD_TYPE=Release \
  -DFFMPEG=OFF \
  -DBINKDEC=ON \
  -DUSE_MoltenVK=ON \
  -DUSE_METAL2=OFF \
  ${OPENAL_PREFIX:+-DOPENAL_LIBRARY=$OPENAL_PREFIX/lib/libopenal.dylib} \
  ${OPENAL_PREFIX:+-DOPENAL_INCLUDE_DIR=$OPENAL_PREFIX/include} \
  -DCMAKE_POLICY_DEFAULT_CMP0142=NEW \
  ../neo \
  -Wno-dev

