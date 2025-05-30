#!/bin/bash

cd ..
rm -rf android-release
mkdir android-release
cd android-release

# Set Android NDK root
if [ -z "$ANDROID_NDK_HOME" ]; then
  ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk-bundle
fi

if [ ! -d "$ANDROID_NDK_HOME" ]; then
  echo "Error: ANDROID_NDK_HOME is not set or path is invalid."
  exit 1
fi

# Set OpenAL paths (optional)
if [ -z "$OPENAL_ANDROID_PREFIX" ]; then
  echo "Note: OPENAL_ANDROID_PREFIX not set. Skipping OpenAL unless precompiled version is linked manually."
else
  OPENAL_INCLUDE_ARG="-DOPENAL_INCLUDE_DIR=$OPENAL_ANDROID_PREFIX/include"
  OPENAL_LIBRARY_ARG="-DOPENAL_LIBRARY=$OPENAL_ANDROID_PREFIX/lib/armeabi-v7a/libopenal.so"
fi

# Build with Android toolchain
cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DFFMPEG=OFF \
  -DBINKDEC=ON \
  -DUSE_MoltenVK=OFF \
  -DUSE_VULKAN=ON \
  -DUSE_SDL2=ON \
  ${OPENAL_INCLUDE_ARG} \
  ${OPENAL_LIBRARY_ARG} \
  ../neo \
  -Wno-dev

