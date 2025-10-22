#-------------------------------------------------
# Valkyrie Engine - Samurai Babel MMO RPG
# Qt Creator Project File
#-------------------------------------------------

QT       += core gui widgets
greaterThan(QT_MAJOR_VERSION, 5): QT += widgets

CONFIG += c++17
CONFIG -= app_bundle

# Application name and version
TARGET = Valkyrie
TEMPLATE = app
VERSION = 1.0.0

# Defines
DEFINES += QT_DEPRECATED_WARNINGS
DEFINES += USE_QT6

# macOS specific settings
macx {
    CONFIG += sdk_no_version_check
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 11.0
    
    # Detect architecture
    contains(QT_ARCH, arm64) {
        message("Building for Apple Silicon (arm64)")
        QMAKE_APPLE_DEVICE_ARCHS = arm64
    } else:contains(QT_ARCH, x86_64) {
        message("Building for Intel Mac (x86_64)")
        QMAKE_APPLE_DEVICE_ARCHS = x86_64
    } else {
        message("Building Universal Binary")
        QMAKE_APPLE_DEVICE_ARCHS = arm64 x86_64
    }
    
    # SDL2 paths for macOS (Homebrew)
    INCLUDEPATH += /opt/homebrew/include/SDL2
    INCLUDEPATH += /opt/homebrew/include
    
    LIBS += -L/opt/homebrew/lib
    LIBS += -lSDL2
    LIBS += -lSDL2_image
    
    # MoltenVK for Vulkan on macOS
    LIBS += -L/opt/homebrew/lib -lMoltenVK
    INCLUDEPATH += /opt/homebrew/include
    DEFINES += USE_MOLTENVK
    
    # macOS Frameworks
    LIBS += -framework Metal
    LIBS += -framework MetalKit
    LIBS += -framework Foundation
    LIBS += -framework QuartzCore
    LIBS += -framework OpenGL
    LIBS += -lcurl
    
    # App bundle settings
    QMAKE_INFO_PLIST = Info.plist
    ICON = sys/posix/res/Valkyrie.icns
    
    # Copy resources to bundle
    APP_RES.files = SamuraiBabel.png
    APP_RES.path = Contents/Resources
    QMAKE_BUNDLE_DATA += APP_RES
}

# Linux specific settings
unix:!macx {
    message("Configuring for Linux")
    
    # Detect if Anbernic device (ARM64)
    contains(QT_ARCH, arm64)|contains(QT_ARCH, aarch64) {
        message("Detected ARM64 architecture - checking for Anbernic device")
        
        # Check if running on Anbernic
        exists(/sys/firmware/devicetree/base/model) {
            message("Anbernic device detected!")
            DEFINES += ANBERNIC_BUILD
            
            # Optimize for ARM Cortex-A55 (common in Anbernic devices)
            QMAKE_CXXFLAGS += -march=armv8-a -mtune=cortex-a55
            
            # Use OpenGL ES for Anbernic
            LIBS += -lGLESv2
        } else {
            message("Generic ARM64 Linux")
        }
    } else {
        message("Desktop Linux (x86_64)")
    }
    
    # SDL2 using pkg-config
    CONFIG += link_pkgconfig
    PKGCONFIG += sdl2 SDL2_image
    
    # Vulkan
    PKGCONFIG += vulkan
    
    # Additional libraries
    LIBS += -lpthread
    
    # X11 for desktop Linux
    !contains(DEFINES, ANBERNIC_BUILD) {
        PKGCONFIG += x11
    }
    
    # Install path for Anbernic
    contains(DEFINES, ANBERNIC_BUILD) {
        target.path = /roms/ports
        INSTALLS += target
        
        # Create launch script
        launcher.files = valkyrie_launch.sh
        launcher.path = /roms/ports
        INSTALLS += launcher
    }
}

# Windows specific settings
win32 {
    message("Configuring for Windows")
    
    DEFINES += WINDOWS
    
    # SDL2 paths (adjust to your installation)
    INCLUDEPATH += C:/SDL2/include
    LIBS += -LC:/SDL2/lib -lSDL2 -lSDL2_image
    
    # DirectX 9 (optional)
    exists(C:/DXSDK/Include/d3d9.h) {
        message("DirectX 9 found")
        INCLUDEPATH += C:/DXSDK/Include
        LIBS += -LC:/DXSDK/Lib/x86 -ld3d9 -ld3dx9
    }
    
    # OpenGL
    LIBS += -lopengl32 -lglu32
    
    # Windows version
    DEFINES += WINDOWS10
    QMAKE_TARGET_PRODUCT = "Valkyrie Engine"
    QMAKE_TARGET_DESCRIPTION = "Samurai Babel MMO RPG"
    QMAKE_TARGET_COPYRIGHT = "Copyright 2024"
    RC_ICONS = sys/win32/res/Valkyrie.ico
}

# Source files
SOURCES += \
    main.cpp \
    game_utils.cpp \
    src/ai.cpp \
    src/api.cpp \
    src/camera.cpp \
    src/commands.cpp \
    src/credits.cpp \
    src/gamepad.cpp \
    src/MainWindow.cpp \
    src/SDLWidget.cpp \
    src/AnbernicConfig.cpp \
    srv/serverRegistration.cpp

# Header files
HEADERS += \
    game_utils.h \
    src/ai.h \
    src/api.h \
    src/commands.h \
    src/gamepad.h \
    src/MainWindow.h \
    src/SDLWidget.h \
    src/AnbernicConfig.h \
    srv/serverRegistration.h

# Forms (if any)
FORMS +=

# Resources
RESOURCES +=

# Distribution files
DISTFILES += \
    CMakeLists.txt \
    README.md \
    SamuraiBabel.png

# Output directories
CONFIG(debug, debug|release) {
    DESTDIR = build/debug
    OBJECTS_DIR = build/debug/obj
    MOC_DIR = build/debug/moc
    RCC_DIR = build/debug/rcc
    UI_DIR = build/debug/ui
} else {
    DESTDIR = build/release
    OBJECTS_DIR = build/release/obj
    MOC_DIR = build/release/moc
    RCC_DIR = build/release/rcc
    UI_DIR = build/release/ui
}

# Additional include paths
INCLUDEPATH += $$PWD
INCLUDEPATH += $$PWD/src
INCLUDEPATH += $$PWD/srv

# Compiler warnings
QMAKE_CXXFLAGS += -Wall -Wextra

# Optimization for release builds
CONFIG(release, debug|release) {
    QMAKE_CXXFLAGS += -O3
    
    # Strip symbols on Linux/macOS
    unix {
        QMAKE_POST_LINK += strip $$TARGET
    }
}

# Optional features (uncomment to enable)
# USE_KCC: Kayte C Compiler support
#DEFINES += USE_KCC_SCRIPTS
#SOURCES += src/kcc_support.cpp
#HEADERS += src/kcc_support.h

# OpenAL support
#CONFIG += openal
#openal {
#    DEFINES += USE_OPENAL
#    macx: LIBS += -framework OpenAL
#    unix:!macx: LIBS += -lopenal
#    win32: LIBS += -lOpenAL32
#}

# FFMPEG support for video
#CONFIG += ffmpeg
#ffmpeg {
#    DEFINES += USE_FFMPEG
#    PKGCONFIG += libavcodec libavformat libavutil libswscale
#}

# Default rules for deployment
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

# Print configuration summary
message("")
message("=== Valkyrie Engine Build Configuration ===")
message("Target: $$TARGET")
message("Version: $$VERSION")
message("Qt Version: $$[QT_VERSION]")
message("Architecture: $$QT_ARCH")
message("Platform: $$QMAKE_PLATFORM")
message("Build Type: $$CONFIG")
message("Output: $$DESTDIR")
message("===========================================")
message("")
