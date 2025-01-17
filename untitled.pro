# Deployment Target and Mode
APPLE_DEPLOYMENT_TARGET = 11.0
APPLE_DEPLOYMENT_MODE = release

# Project Template and Configuration
TEMPLATE = app
CONFIG += console c++17
CONFIG -= app_bundle
CONFIG -= qt

# Skip SDK Version Check
CONFIG += sdk_no_version_check

# Add Required Qt Modules (optional if not using Qt)
QT += sql

# Source Files
SOURCES += \
    ai.cpp \
    camera.cpp \
    gamepad.cpp \
    main.cpp
    #srv/serverRegistration.cpp

# Distribution Files
DISTFILES += \
    Makefile \
    MetalRenderer.m

# Include Paths
INCLUDEPATH += \
    $$PWD \
    /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk/usr/include \
    /opt/homebrew/include \
    /opt/homebrew/include/SDL2

# Library Paths and Frameworks
LIBS += \
    -L/opt/homebrew/lib \
    -lSDL2 \
    -lSDL2_image \
    -framework OpenGL \
    -framework Metal \
    -framework QuartzCore

# Additional Compiler and Linker Flags
QMAKE_CFLAGS += -fobjc-arc
QMAKE_CXXFLAGS += -fobjc-arc
QMAKE_LFLAGS += -fobjc-arc

# macOS/iOS Specific Configuration
macx {
    # Set deployment target for macOS/iOS
    QMAKE_MACOSX_DEPLOYMENT_TARGET = $$APPLE_DEPLOYMENT_TARGET

    # Include iOS-specific libraries
    #LIBS += -framework UIKit -framework CoreGraphics
}

# iOS-specific settings
ios {
    # Set deployment target for iOS
    QMAKE_IOS_DEPLOYMENT_TARGET = $$APPLE_DEPLOYMENT_TARGET

    # Link against iOS libraries for Metal
    LIBS += -framework Metal -framework QuartzCore -framework CoreGraphics

    # Disable OpenGL warnings (as OpenGL is deprecated for iOS)
    DEFINES += GL_SILENCE_DEPRECATION
}

# Android-specific settings
android {
    # Set up Android NDK and include paths
    ANDROID_NDK_HOME = /path/to/your/ndk
    ANDROID_ABI = arm64-v8a  # Change this if you target different architecture
    ANDROID_TARGET = android-21  # Minimum SDK version

    # Link against SDL2 and SDL2_image on Android
    LIBS += -lSDL2 -lSDL2_image

    # Use OpenGL ES for Android (GLES2)
    QMAKE_CXXFLAGS += -DGL_ES

    # Set up Android deployment target
    QMAKE_ANDROID_DEPLOYMENT_TARGET = android-21
}

# Ensure platform-specific flags are applied
!macx {
    QMAKE_LFLAGS += -lGLESv2
}

# Ensure Android has the correct flags
android {
    QMAKE_LFLAGS += -lGLESv2
    QMAKE_LFLAGS += -lEGL
}

# Windows-specific settings
win32 {
    # Set deployment target for Windows
    QMAKE_WINDOWS_DEPLOYMENT_TARGET = win11

    # Include paths for Windows
    INCLUDEPATH += \
        C:/path/to/SDL2/include

    # Library paths and dependencies for Windows
    LIBS += \
        -LC:/path/to/SDL2/lib \
        -lSDL2 \
        -lSDL2_image \
        -lopengl32

    # Additional compiler and linker flags for Windows
    QMAKE_CXXFLAGS += -DWINDOWS
}

# Linux (arm64) specific settings
linux {
    # Check if the target architecture is arm64
    QMAKE_LFLAGS += -march=armv8-a

    # Include paths for Linux arm64
    INCLUDEPATH += \
        /usr/include/SDL2

    # Library paths and dependencies for Linux arm64
    LIBS += \
        -L/usr/lib/aarch64-linux-gnu \
        -lSDL2 \
        -lSDL2_image \
        -lGL \
        -lEGL

    # Additional compiler and linker flags for Linux arm64
    QMAKE_CXXFLAGS += -DLINUX_ARM64
}


# General Compilation Flags
QMAKE_CFLAGS += -fobjc-arc
QMAKE_CXXFLAGS += -fobjc-arc
QMAKE_LFLAGS += -fobjc-arc

# Set the correct build configuration
CONFIG += release

HEADERS += \
    ai.h update
