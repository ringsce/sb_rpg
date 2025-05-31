cmake_minimum_required(VERSION 3.16)

# Set application name
if(NOT DEFINED APP_NAME)
    set(APP_NAME valkyrie)
endif()
project(${APP_NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set macOS deployment target
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
endif()

# CMake IDE and VS settings
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.6")
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${APP_NAME})
endif()

# Options
option(STANDALONE                "Skip Valkyrie base/ folder and use content/ instead" ON)
option(FORCE_COLOR_OUTPUT        "Always produce ANSI-colored output (GNU/Clang only)" OFF)
option(COMPILE_COMMANDS          "Generate compile_commands.json" OFF)
option(USE_PRECOMPILED_HEADERS   "Use precompiled headers during build" ON)
option(OPENAL                    "Use OpenAL soft instead of XAudio2" OFF)
option(FFMPEG                    "Use FFMPEG to render Bink videos" OFF)
option(BINKDEC                   "Use included libbinkdec to render Bink videos" ON)
option(USE_MoltenVK              "Use MoltenVK instead of Vulkan loader on macOS" ON)
option(ONATIVE                   "Optimize for the host CPU" OFF)
option(WINDOWS10                 "Build for Windows 10+" ON)
option(USE_SYSTEM_ZLIB           "Use the system zlib instead of the bundled one" OFF)
option(USE_SYSTEM_RAPIDJSON      "Use the system rapidjson instead of the bundled one" OFF)
option(USE_SDL3                  "Use SDL3 instead of SDL2 if available" OFF)

if(USE_MoltenVK)
    add_definitions(-DUSE_MOLTENVK)
endif()


# Source files
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

# SDL2/SDL3
if(USE_SDL3)
    find_package(SDL3 REQUIRED)
    include_directories(${SDL3_INCLUDE_DIRS})
    list(APPEND EXTRA_LIBS ${SDL3_LIBRARIES})
else()
    find_package(SDL2 REQUIRED)
    include_directories(${SDL2_INCLUDE_DIRS})
    list(APPEND EXTRA_LIBS ${SDL2_LIBRARIES})
endif()

find_package(SDL2_image REQUIRED)
include_directories(${SDL2_IMAGE_INCLUDE_DIRS})
list(APPEND EXTRA_LIBS ${SDL2_IMAGE_LIBRARIES})

# Platform-specific config
if(WIN32)
    add_definitions(-DWINDOWS)
    find_path(DIRECTX9_INCLUDE_DIR d3d9.h PATHS "C:/DXSDK/Include" "C:/Program Files (x86)/Microsoft DirectX SDK/Include")
    find_library(DIRECTX9_LIBRARY d3d9 PATHS "C:/DXSDK/Lib/x86" "C:/Program Files (x86)/Microsoft DirectX SDK/Lib/x86")
    find_library(DIRECTX9_D3DX_LIBRARY d3dx9 PATHS "C:/DXSDK/Lib/x86" "C:/Program Files (x86)/Microsoft DirectX SDK/Lib/x86")

    if(DIRECTX9_INCLUDE_DIR AND DIRECTX9_LIBRARY)
        message(STATUS "DirectX 9 detected")
        include_directories(${DIRECTX9_INCLUDE_DIR})
        list(APPEND EXTRA_LIBS ${DIRECTX9_LIBRARY} ${DIRECTX9_D3DX_LIBRARY})
    else()
        message(WARNING "DirectX 9 not found.")
    endif()

elseif(APPLE)
    message(STATUS "Configuring for macOS...")

    # SDL includes
    include_directories(/opt/homebrew/include /opt/homebrew/include/SDL3)
    link_directories(/opt/homebrew/lib)

    # Always link Metal 2 and QuartzCore
    list(APPEND EXTRA_LIBS Metal QuartzCore)

    if(USE_MoltenVK)
        message(STATUS "Using MoltenVK as Vulkan backend")

        # Find MoltenVK framework or dynamic lib
        find_library(MOLTENVK_LIB MoltenVK
                PATHS /opt/homebrew/lib /usr/local/lib /Library/Frameworks
                NO_DEFAULT_PATH
        )
        find_path(MOLTENVK_INCLUDE_DIR MoltenVK/mvk_vulkan.h
                PATHS /opt/homebrew/include /usr/local/include /Library/Frameworks
                NO_DEFAULT_PATH
        )

        if(MOLTENVK_LIB AND MOLTENVK_INCLUDE_DIR)
            message(STATUS "MoltenVK found at ${MOLTENVK_LIB}")
            include_directories(${MOLTENVK_INCLUDE_DIR})
            list(APPEND EXTRA_LIBS ${MOLTENVK_LIB})
            add_definitions(-DUSE_MOLTENVK)
        else()
            message(FATAL_ERROR "MoltenVK not found. Install via Homebrew: brew install molten-vk")
        endif()
    else()
        message(STATUS "Using system Vulkan (non-MoltenVK)")
        find_package(Vulkan REQUIRED)
        include_directories(${Vulkan_INCLUDE_DIR})
        list(APPEND EXTRA_LIBS ${Vulkan_LIBRARIES})
    endif()

    # SDL linking
    list(APPEND EXTRA_LIBS SDL2 SDL2_image)

elseif(ANDROID)
    add_definitions(-DGL_ES)
    set(ANDROID_ABI arm64-v8a)
    set(ANDROID_PLATFORM android-21)
    list(APPEND EXTRA_LIBS SDL2 GLESv2 EGL)

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
    list(APPEND EXTRA_LIBS SDL2 GL EGL)
endif()

# macOS bundle support
if(APPLE AND MACOSX_BUNDLE)
    set(MACOS_RESOURCES sys/posix/res/Valkyrie.icns ../base)
    source_group("Resources" FILES ${MACOS_RESOURCES})
    set_source_files_properties(${MACOS_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

    set(MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME})
    set(MACOSX_BUNDLE_BUNDLE_VERSION 1.0.0)
    set(MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0.0)
    set(MACOSX_BUNDLE_ICON_FILE Valkyrie.icns)

    add_executable(${APP_NAME} MACOSX_BUNDLE ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES} ${MACOS_RESOURCES})
else()
    add_executable(${APP_NAME} ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES})
endif()

# Optional OpenAL
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
    list(APPEND EXTRA_LIBS OpenAL32)
endif()

# Optional Vulkan support
if(USE_VULKAN)
    add_dependencies(${APP_NAME} nvrhi_vk)
endif()

# Link all collected libraries
# Link all collected libraries
target_link_libraries(${APP_NAME} PRIVATE ${EXTRA_LIBS})

if(APPLE)
    find_library(METAL_FRAMEWORK Metal)
    find_library(METALKIT_FRAMEWORK MetalKit)
    find_library(FOUNDATION_FRAMEWORK Foundation)

    target_link_libraries(${APP_NAME} PRIVATE
            ${METAL_FRAMEWORK}
            ${METALKIT_FRAMEWORK}
            ${FOUNDATION_FRAMEWORK}
    )
endif()
