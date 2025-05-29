cmake_minimum_required(VERSION 3.16)

# Set the application name
if(NOT DEFINED APP_NAME)
    set(APP_NAME valkyrie)
endif()
project(${APP_NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Deployment target for macOS/iOS
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
endif()

# Use folders in IDEs (like Visual Studio)
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.6")
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${APP_NAME})
endif()

# Option to use standalone content
option(STANDALONE "Skip DOOM-3-BFG base/ folder and use content/ instead" ON)

# Source and header files
set(VALKYRIE_SOURCES
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

set(VALKYRIE_INCLUDES
        game_utils.h
        src/ai.h
        src/api.h
        src/commands.h
        src/gamepad.h
)

# Detect SDL3 (fallback to SDL2)
find_path(SDL3_INCLUDE_DIR SDL3/SDL.h PATHS /usr/include /opt/homebrew/include /usr/local/include)
find_library(SDL3_LIBRARY NAMES SDL3 PATHS /usr/lib /opt/homebrew/lib /usr/local/lib)

set(LIBS "")
if(SDL3_INCLUDE_DIR AND SDL3_LIBRARY)
    message(STATUS "Using SDL3")
    include_directories(${SDL3_INCLUDE_DIR})
    list(APPEND LIBS ${SDL3_LIBRARY})
else()
    message(STATUS "SDL3 not found, falling back to SDL2")
    find_package(SDL2 REQUIRED)
    include_directories(${SDL2_INCLUDE_DIRS})
    list(APPEND LIBS ${SDL2_LIBRARIES})
endif()

# Platform-specific configurations
if(WIN32)
    add_definitions(-DWINDOWS)

    # Optional DirectX 9 support
    find_path(DIRECTX9_INCLUDE_DIR d3d9.h PATHS "C:/DXSDK/Include" "C:/Program Files (x86)/Microsoft DirectX SDK/Include")
    find_library(DIRECTX9_LIBRARY d3d9 PATHS "C:/DXSDK/Lib/x86" "C:/Program Files (x86)/Microsoft DirectX SDK/Lib/x86")
    find_library(DIRECTX9_D3DX_LIBRARY d3dx9 PATHS "C:/DXSDK/Lib/x86" "C:/Program Files (x86)/Microsoft DirectX SDK/Lib/x86")

    if(DIRECTX9_INCLUDE_DIR AND DIRECTX9_LIBRARY)
        message(STATUS "DirectX 9 detected")
        include_directories(${DIRECTX9_INCLUDE_DIR})
        list(APPEND LIBS ${DIRECTX9_LIBRARY} ${DIRECTX9_D3DX_LIBRARY})
    else()
        message(WARNING "DirectX 9 not found.")
    endif()
elseif(APPLE)
    include_directories(/opt/homebrew/include /opt/homebrew/include/SDL3)
    link_directories(/opt/homebrew/lib)
    list(APPEND LIBS SDL3 OpenGL Metal QuartzCore)
elseif(ANDROID)
    add_definitions(-DGL_ES)
    set(ANDROID_ABI arm64-v8a)
    set(ANDROID_PLATFORM android-21)
    list(APPEND LIBS SDL3 GLESv2 EGL)
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
    list(APPEND LIBS SDL3 GL EGL)
endif()

# Build target
if(APPLE AND MACOSX_BUNDLE)
    # macOS bundle
    set(MACOS_RESOURCES sys/posix/res/Valkyrie.icns ../base
            src/game_utils.h)
    source_group("Resources" FILES ${MACOS_RESOURCES})
    set_source_files_properties(${MACOS_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

    set(MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME})
    set(MACOSX_BUNDLE_BUNDLE_VERSION 1.0.0)
    set(MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0.0)
    set(MACOSX_BUNDLE_ICON_FILE Valkyrie.icns)

    add_executable(${APP_NAME} MACOSX_BUNDLE ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES} ${MACOS_RESOURCES})
else()
    # Normal executable (Windows/Linux)
    add_executable(${APP_NAME} ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES})
endif()

target_link_libraries(${APP_NAME} ${LIBS})

# OpenAL integration (optional)
if(OPENAL)
    add_definitions(-DUSE_OPENAL)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/libs/openal-soft/include)

    if(CMAKE_CL_64)
        link_directories(${CMAKE_CURRENT_SOURCE_DIR}/libs/openal-soft/lib/win64)
        install(FILES libs/openal-soft/lib/bin/win64/OpenAL32.dll DESTINATION .)
    else()
        link_directories(${CMAKE_CURRENT_SOURCE_DIR}/libs/openal-soft/lib/win32)
        install(FILES
                libs/openal-soft/lib/bin/win32/OpenAL32.dll
                libs/openal-soft/lib/bin/win32/OpenAL32.pdb
                DESTINATION .
        )
    endif()

    list(APPEND LIBS OpenAL32)
endif()

# Vulkan support (optional)
if(USE_VULKAN)
    add_dependencies(${APP_NAME} nvrhi_vk)
endif()
