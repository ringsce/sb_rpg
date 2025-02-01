cmake_minimum_required(VERSION 3.16)
project(SamuraiBabel)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Deployment Target (macOS/iOS)
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
endif()

# Source Files
set(SOURCES
    game_utils.cpp
    src/ai.cpp
    src/api.cpp
    src/camera.cpp
    src/commands.cpp
    src/credits.cpp
    src/gamepad.cpp
    main.cpp
    srv/serverRegistration.cpp
)

# Header Files
set(HEADERS
    game_utils.h
    src/ai.h
    src/api.h
    src/commands.h
    src/gamepad.h
)

# SDL3 Detection (Prefers SDL3, falls back to SDL2)
find_path(SDL3_INCLUDE_DIR SDL3/SDL.h PATHS /usr/include /opt/homebrew/include /usr/local/include)
find_library(SDL3_LIBRARY NAMES SDL3 PATHS /usr/lib /opt/homebrew/lib /usr/local/lib)

if(SDL3_INCLUDE_DIR AND SDL3_LIBRARY)
    message("Using SDL3")
    include_directories(${SDL3_INCLUDE_DIR})
    set(LIBS ${LIBS} ${SDL3_LIBRARY})
else()
    message("SDL3 not found, falling back to SDL2")
    find_package(SDL2 REQUIRED)
    include_directories(${SDL2_INCLUDE_DIRS})
    set(LIBS ${LIBS} ${SDL2_LIBRARIES})
endif()

# Platform-specific configurations
if(WIN32)
    add_definitions(-DWINDOWS)

    # Check for DirectX 9 SDK
    find_path(DIRECTX9_INCLUDE_DIR d3d9.h PATHS "C:/Program Files (x86)/Microsoft DirectX SDK/Include" "C:/DXSDK/Include")
    find_library(DIRECTX9_LIBRARY d3d9 PATHS "C:/Program Files (x86)/Microsoft DirectX SDK/Lib/x86" "C:/DXSDK/Lib/x86")
    find_library(DIRECTX9_D3DX_LIBRARY d3dx9 PATHS "C:/Program Files (x86)/Microsoft DirectX SDK/Lib/x86" "C:/DXSDK/Lib/x86")

    if(DIRECTX9_INCLUDE_DIR AND DIRECTX9_LIBRARY)
        message("DirectX 9 detected")
        include_directories(${DIRECTX9_INCLUDE_DIR})
        set(LIBS ${LIBS} ${DIRECTX9_LIBRARY} ${DIRECTX9_D3DX_LIBRARY})
    else()
        message(WARNING "DirectX 9 not found. The game may not run properly on Windows.")
    endif()

    include_directories(C:/path/to/SDL3/include)
    link_directories(C:/path/to/SDL3/lib)
elseif(APPLE)
    include_directories(/opt/homebrew/include /opt/homebrew/include/SDL3)
    link_directories(/opt/homebrew/lib)
    set(LIBS ${LIBS} SDL3 OpenGL Metal QuartzCore)
elseif(ANDROID)
    set(ANDROID_ABI arm64-v8a)
    set(ANDROID_PLATFORM android-21)
    add_definitions(-DGL_ES)
    set(LIBS ${LIBS} SDL3 GLESv2 EGL)
elseif(UNIX AND NOT APPLE)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        add_definitions(-DLINUX_ARM64)
        include_directories(/usr/include/SDL3)
        link_directories(/usr/lib/aarch64-linux-gnu)
    else()
        add_definitions(-DLINUX_AMD64)
        include_directories(/usr/include/SDL3)
        link_directories(/usr/lib/x86_64-linux-gnu)
    endif()
    set(LIBS ${LIBS} SDL3 GL EGL)
endif()

# Add executable
add_executable(SamuraiBabel ${SOURCES} ${HEADERS})
target_link_libraries(SamuraiBabel ${LIBS})
