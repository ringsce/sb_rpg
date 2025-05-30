#!/bin/bash

cd ..
rm -rf xcode-ios-release
mkdir xcode-ios-release
cd xcode-ios-release

# Optional OpenAL-soft path
if [ -z "$OPENAL_PREFIX" ]; then
  OPENAL_PREFIX=$(brew --prefix openal-soft 2>/dev/null)
  if [ -z "$OPENAL_PREFIX" ]; then
    echo "Warning: openal-soft is not installed via Homebrew."
    echo "Proceeding without OpenAL. Define OPENAL_PREFIX manually if needed."
  fi
fi

# Toolchain from ios-cmake
IOS_TOOLCHAIN=../cmake/ios-cmake/ios.toolchain.cmake

cmake -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE=$IOS_TOOLCHAIN \
  -DPLATFORM=OS64COMBINED \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CONFIGURATION_TYPES="Release;MinSizeRel;RelWithDebInfo" \
  -DMACOSX_BUNDLE=ON \
  -DFFMPEG=OFF \
  -DBINKDEC=ON \
  -DUSE_MoltenVK=OFF \
  -DUSE_METAL2=ON \
  -DRVHI_BACKEND=METAL \
  -DCMAKE_XCODE_GENERATE_SCHEME=ON \
  -DCMAKE_XCODE_SCHEME_ENVIRONMENT="OS_ACTIVITY_MODE=disable" \
  -DCMAKE_XCODE_SCHEME_ENABLE_GPU_API_VALIDATION=OFF \
  ${OPENAL_PREFIX:+-DOPENAL_LIBRARY=$OPENAL_PREFIX/lib/libopenal.dylib} \
  ${OPENAL_PREFIX:+-DOPENAL_INCLUDE_DIR=$OPENAL_PREFIX/include} \
  -DCMAKE_POLICY_DEFAULT_CMP0142=NEW \
  ../neo \
  -Wno-dev

