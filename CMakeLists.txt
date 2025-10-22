cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

# Set application name
if(NOT DEFINED APP_NAME)
    set(APP_NAME Valkyrie)
endif()
project(${APP_NAME})
include(FetchContent)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set macOS deployment target
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")

    # Detect and set architecture
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64" OR CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "arm64")
        set(CMAKE_OSX_ARCHITECTURES "arm64")
        message(STATUS "Building for Apple Silicon (arm64)")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64" OR CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64")
        message(STATUS "Building for Intel Mac (x86_64)")
    else()
        set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
        message(STATUS "Building Universal Binary (arm64 + x86_64)")
    endif()
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
option(USE_KCC                   "Use Kayte C Compiler for game scripts" OFF)
option(USE_QT6                   "Use Qt6 GUI framework" ON)

if(USE_MoltenVK AND APPLE)
    add_definitions(-DUSE_MOLTENVK)
endif()

# Detect platform type FIRST
set(IS_ANBERNIC FALSE)
set(IS_MACOS FALSE)
set(IS_DESKTOP_LINUX FALSE)

if(APPLE)
    set(IS_MACOS TRUE)
    message(STATUS "Platform: macOS")

elseif(UNIX AND NOT APPLE)
    # Linux platform detection
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm" OR CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        # ARM64 Linux - check if it's Anbernic
        if(EXISTS "/sys/firmware/devicetree/base/model")
            file(READ "/sys/firmware/devicetree/base/model" DEVICE_MODEL)
            string(TOLOWER "${DEVICE_MODEL}" DEVICE_MODEL_LOWER)
            if(DEVICE_MODEL_LOWER MATCHES "anbernic" OR DEVICE_MODEL_LOWER MATCHES "rg[0-9]")
                set(IS_ANBERNIC TRUE)
                add_definitions(-DANBERNIC_BUILD)
                message(STATUS "Platform: Anbernic handheld device (ARM64 Linux)")
                message(STATUS "  Device model: ${DEVICE_MODEL}")

                # Optimize for ARM Cortex-A55 (common in Anbernic devices)
                set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a -mtune=cortex-a55")
            else()
                set(IS_DESKTOP_LINUX TRUE)
                message(STATUS "Platform: Generic ARM64 Linux")
            endif()
        elseif(EXISTS "/sys/firmware/devicetree/base/compatible")
            file(READ "/sys/firmware/devicetree/base/compatible" DEVICE_COMPAT)
            string(TOLOWER "${DEVICE_COMPAT}" DEVICE_COMPAT_LOWER)
            if(DEVICE_COMPAT_LOWER MATCHES "anbernic" OR DEVICE_COMPAT_LOWER MATCHES "rockchip,rk35")
                set(IS_ANBERNIC TRUE)
                add_definitions(-DANBERNIC_BUILD)
                message(STATUS "Platform: Anbernic handheld device (ARM64 Linux)")
                message(STATUS "  Device compatible: ${DEVICE_COMPAT}")

                set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a -mtune=cortex-a55")
            else()
                set(IS_DESKTOP_LINUX TRUE)
                message(STATUS "Platform: Generic ARM64 Linux")
            endif()
        else()
            # No devicetree, probably standard ARM64 Linux
            set(IS_DESKTOP_LINUX TRUE)
            message(STATUS "Platform: ARM64 Linux Desktop")
        endif()
    else()
        # x86_64 or other architecture
        set(IS_DESKTOP_LINUX TRUE)
        message(STATUS "Platform: Desktop Linux (${CMAKE_SYSTEM_PROCESSOR})")
    endif()

elseif(WIN32)
    message(STATUS "Platform: Windows")
endif()

# Qt6 Configuration - happens before source collection
set(QT6_ENABLED FALSE)
if(USE_QT6)
    message(STATUS "Looking for Qt6...")

    # Enable Qt CMake automation
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC ON)

    # Qt6 for desktop platforms
    if(IS_MACOS OR IS_DESKTOP_LINUX)
        find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
        if(Qt6_FOUND)
            message(STATUS "Qt6 found and enabled for desktop")
            set(QT6_ENABLED TRUE)
            add_definitions(-DUSE_QT6)
        endif()

        # Qt6 optional for Anbernic
    elseif(IS_ANBERNIC)
        find_package(Qt6 QUIET COMPONENTS Core Gui Widgets)
        if(Qt6_FOUND)
            message(STATUS "Qt6 found on Anbernic device")
            set(QT6_ENABLED TRUE)
            add_definitions(-DUSE_QT6)
        else()
            message(STATUS "Qt6 not available on Anbernic - building without Qt GUI")
            set(QT6_ENABLED FALSE)
        endif()
    endif()
else()
    message(STATUS "Qt6 disabled (USE_QT6=OFF)")
endif()

message(STATUS "QT6_ENABLED = ${QT6_ENABLED}")

# Find KCC (Kayte C Compiler) for game scripts
if(USE_KCC)
    find_package(KCC)

    if(KCC_FOUND)
        message(STATUS "Kayte C Compiler (KCC) enabled for Samurai Babel RPG scripts")
        add_definitions(-DUSE_KCC_SCRIPTS)

        set(KCC_SCRIPT_SOURCES
                # Add your .kcc script files here
        )

        if(KCC_SCRIPT_SOURCES)
            kcc_compile_files(KCC_COMPILED_OBJECTS ${KCC_SCRIPT_SOURCES})
            message(STATUS "Compiling ${CMAKE_CURRENT_LIST_LENGTH} KCC script files")
        endif()
    else()
        message(WARNING "KCC not found - building without KCC script support")
    endif()
endif()

# ============================================================================
# SOURCE FILE COLLECTION
# ============================================================================
message(STATUS "")
message(STATUS "Collecting source files...")

# Base sources - always included
set(VALKYRIE_SOURCES
        src/ai.cpp
        src/api.cpp
        src/camera.cpp
        src/commands.cpp
        src/credits.cpp
        src/gamepad.cpp
        src/AnbernicConfig.cpp
        srv/serverRegistration.cpp
)

# Find main.cpp location
if(EXISTS ${CMAKE_SOURCE_DIR}/main.cpp)
    list(APPEND VALKYRIE_SOURCES main.cpp)
    message(STATUS "  ✓ main.cpp (root)")
elseif(EXISTS ${CMAKE_SOURCE_DIR}/src/main.cpp)
    list(APPEND VALKYRIE_SOURCES src/main.cpp)
    message(STATUS "  ✓ main.cpp (src/)")
else()
    message(FATAL_ERROR "main.cpp not found in root or src/ directory!")
endif()

# Find game_utils.cpp location
if(EXISTS ${CMAKE_SOURCE_DIR}/game_utils.cpp)
    list(APPEND VALKYRIE_SOURCES game_utils.cpp)
    message(STATUS "  ✓ game_utils.cpp (root)")
elseif(EXISTS ${CMAKE_SOURCE_DIR}/src/game_utils.cpp)
    list(APPEND VALKYRIE_SOURCES src/game_utils.cpp)
    message(STATUS "  ✓ game_utils.cpp (src/)")
else()
    message(FATAL_ERROR "game_utils.cpp not found in root or src/ directory!")
endif()

# Qt6-specific sources
if(QT6_ENABLED)
    message(STATUS "  ✓ Qt6 enabled - adding Qt GUI sources")

    if(EXISTS ${CMAKE_SOURCE_DIR}/src/SDLWidget.cpp)
        list(APPEND VALKYRIE_SOURCES src/SDLWidget.cpp)
        message(STATUS "    - SDLWidget.cpp")
    else()
        message(FATAL_ERROR "src/SDLWidget.cpp not found!")
    endif()

    if(EXISTS ${CMAKE_SOURCE_DIR}/src/MainWindow.cpp)
        list(APPEND VALKYRIE_SOURCES src/MainWindow.cpp)
        message(STATUS "    - MainWindow.cpp")
    else()
        message(FATAL_ERROR "src/MainWindow.cpp not found!")
    endif()
else()
    message(STATUS "  ✗ Qt6 disabled - skipping Qt GUI sources")
endif()

# Add KCC compiled objects
if(KCC_FOUND AND KCC_COMPILED_OBJECTS)
    list(APPEND VALKYRIE_SOURCES ${KCC_COMPILED_OBJECTS})
    message(STATUS "  ✓ Added ${CMAKE_CURRENT_LIST_LENGTH} KCC compiled objects")
endif()

# Print final source list
message(STATUS "")
message(STATUS "Final source files (${list_length} files):")
foreach(src ${VALKYRIE_SOURCES})
    message(STATUS "  - ${src}")
endforeach()
message(STATUS "")

# Header files
set(VALKYRIE_INCLUDES
        game_utils.h
        src/ai.h
        src/api.h
        src/commands.h
        src/gamepad.h
        src/ANBERNIC_CONFIG.h
        srv/serverRegistration.h
        src/MainWindow.h
)

if(QT6_ENABLED)
    list(APPEND VALKYRIE_INCLUDES
            src/SDLWidget.h
            src/MainWindow.h
    )
endif()

# ============================================================================
# SDL2/SDL3 Configuration
# ============================================================================
if(USE_SDL3)
    message(STATUS "Looking for SDL3...")
    find_package(SDL3 QUIET)

    if(SDL3_FOUND)
        message(STATUS "SDL3 found and enabled")
        include_directories(${SDL3_INCLUDE_DIRS})
        list(APPEND EXTRA_LIBS ${SDL3_LIBRARIES})
        add_definitions(-DUSE_SDL3)

        find_package(SDL3_image QUIET)
        if(SDL3_image_FOUND)
            include_directories(${SDL3_IMAGE_INCLUDE_DIRS})
            list(APPEND EXTRA_LIBS ${SDL3_IMAGE_LIBRARIES})
        else()
            message(WARNING "SDL3_image not found, falling back to SDL2_image")
            find_package(SDL2_image REQUIRED)
            include_directories(${SDL2_IMAGE_INCLUDE_DIRS})
            list(APPEND EXTRA_LIBS ${SDL2_IMAGE_LIBRARIES})
        endif()
    else()
        message(WARNING "SDL3 not found, falling back to SDL2")
        set(USE_SDL3 OFF)
    endif()
endif()

# SDL2 configuration
if(NOT USE_SDL3)
    message(STATUS "Using SDL2")

    if(APPLE)
        # macOS Homebrew paths
        set(CMAKE_PREFIX_PATH "/opt/homebrew/opt/sdl2;/opt/homebrew/opt/sdl2_image;${CMAKE_PREFIX_PATH}")
        set(SDL2_DIR "/opt/homebrew/opt/sdl2/lib/cmake/SDL2")
    endif()

    find_package(SDL2 REQUIRED CONFIG)

    if(NOT SDL2_FOUND)
        if(APPLE)
            message(FATAL_ERROR "SDL2 not found! Install with: brew install sdl2 sdl2_image")
        else()
            message(FATAL_ERROR "SDL2 not found! Install with: sudo apt install libsdl2-dev libsdl2-image-dev")
        endif()
    endif()

    message(STATUS "SDL2 found at: ${SDL2_DIR}")

    # Find SDL2_image
    if(APPLE)
        set(SDL2_IMAGE_DIR "/opt/homebrew/opt/sdl2_image/lib/cmake/SDL2_image")
        find_package(SDL2_image QUIET CONFIG PATHS ${SDL2_IMAGE_DIR})
    else()
        find_package(SDL2_image QUIET CONFIG)
    endif()

    # Fallback: pkg-config
    if(NOT SDL2_image_FOUND)
        find_package(PkgConfig QUIET)
        if(PKG_CONFIG_FOUND)
            pkg_check_modules(SDL2_IMAGE QUIET SDL2_image)
        endif()
    endif()

    # Fallback: manual search
    if(NOT SDL2_image_FOUND AND NOT SDL2_IMAGE_FOUND)
        find_path(SDL2_IMAGE_INCLUDE_DIR SDL_image.h
                PATHS /opt/homebrew/opt/sdl2_image/include/SDL2
                /usr/include/SDL2
                /usr/local/include/SDL2
        )
        find_library(SDL2_IMAGE_LIBRARY
                NAMES SDL2_image libSDL2_image
                PATHS /opt/homebrew/opt/sdl2_image/lib
                /usr/lib
                /usr/local/lib
        )

        if(SDL2_IMAGE_INCLUDE_DIR AND SDL2_IMAGE_LIBRARY)
            set(SDL2_IMAGE_FOUND TRUE)
            set(SDL2_IMAGE_LIBRARIES ${SDL2_IMAGE_LIBRARY})
            set(SDL2_IMAGE_INCLUDE_DIRS ${SDL2_IMAGE_INCLUDE_DIR})
            message(STATUS "SDL2_image found manually at: ${SDL2_IMAGE_LIBRARY}")
        else()
            message(FATAL_ERROR "SDL2_image not found!")
        endif()
    endif()

    # Link SDL2
    if(TARGET SDL2::SDL2)
        list(APPEND EXTRA_LIBS SDL2::SDL2)
        message(STATUS "Linking SDL2::SDL2 target")
    else()
        include_directories(${SDL2_INCLUDE_DIRS})
        list(APPEND EXTRA_LIBS ${SDL2_LIBRARIES})
    endif()

    # Link SDL2_image
    if(TARGET SDL2_image::SDL2_image)
        list(APPEND EXTRA_LIBS SDL2_image::SDL2_image)
        message(STATUS "Linking SDL2_image::SDL2_image target")
    else()
        include_directories(${SDL2_IMAGE_INCLUDE_DIRS})
        list(APPEND EXTRA_LIBS ${SDL2_IMAGE_LIBRARIES})
    endif()
endif()

# ============================================================================
# Platform-specific configuration
# ============================================================================
if(WIN32)
    add_definitions(-DWINDOWS)
    find_path(DIRECTX9_INCLUDE_DIR d3d9.h PATHS "C:/DXSDK/Include")
    find_library(DIRECTX9_LIBRARY d3d9 PATHS "C:/DXSDK/Lib/x86")

    if(DIRECTX9_INCLUDE_DIR AND DIRECTX9_LIBRARY)
        message(STATUS "DirectX 9 detected")
        include_directories(${DIRECTX9_INCLUDE_DIR})
        list(APPEND EXTRA_LIBS ${DIRECTX9_LIBRARY})
    endif()

elseif(APPLE)
    message(STATUS "Configuring for macOS...")

    if(USE_MoltenVK)
        find_library(MOLTENVK_LIB MoltenVK PATHS /opt/homebrew/lib NO_DEFAULT_PATH)
        find_path(MOLTENVK_INCLUDE_DIR MoltenVK/mvk_vulkan.h PATHS /opt/homebrew/include NO_DEFAULT_PATH)

        if(MOLTENVK_LIB AND MOLTENVK_INCLUDE_DIR)
            message(STATUS "MoltenVK found at ${MOLTENVK_LIB}")
            include_directories(${MOLTENVK_INCLUDE_DIR})
            list(APPEND EXTRA_LIBS ${MOLTENVK_LIB})
        else()
            message(FATAL_ERROR "MoltenVK not found. Install: brew install molten-vk")
        endif()
    else()
        find_package(Vulkan REQUIRED)
        include_directories(${Vulkan_INCLUDE_DIR})
        list(APPEND EXTRA_LIBS ${Vulkan_LIBRARIES})
    endif()

    # Apple frameworks
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
    find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)
    find_package(CURL REQUIRED)

    list(APPEND EXTRA_LIBS
            ${METAL_FRAMEWORK}
            ${METALKIT_FRAMEWORK}
            ${FOUNDATION_FRAMEWORK}
            ${QUARTZCORE_FRAMEWORK}
            ${CURL_LIBRARIES}
    )

elseif(UNIX AND NOT APPLE)
    message(STATUS "Configuring for Linux...")

    # Vulkan
    find_package(Vulkan REQUIRED)
    include_directories(${Vulkan_INCLUDE_DIR})
    list(APPEND EXTRA_LIBS ${Vulkan_LIBRARIES})

    # Threads
    find_package(Threads REQUIRED)
    list(APPEND EXTRA_LIBS Threads::Threads)

    # X11 for desktop Linux (not Anbernic)
    if(NOT IS_ANBERNIC)
        find_package(X11 REQUIRED)
        include_directories(${X11_INCLUDE_DIR})
        list(APPEND EXTRA_LIBS ${X11_LIBRARIES})
        message(STATUS "X11 support enabled")
    endif()

    # Anbernic-specific optimizations
    if(IS_ANBERNIC)
        message(STATUS "Applying Anbernic optimizations...")

        # Mali GPU library (if available)
        find_library(MALI_LIB Mali PATHS /usr/lib /usr/local/lib)
        if(MALI_LIB)
            list(APPEND EXTRA_LIBS ${MALI_LIB})
            message(STATUS "Mali GPU library: ${MALI_LIB}")
        endif()

        # Use OpenGL ES for better performance
        find_package(OpenGLES2)
        if(OPENGLES2_FOUND)
            include_directories(${OPENGLES2_INCLUDE_DIR})
            list(APPEND EXTRA_LIBS ${OPENGLES2_LIBRARIES})
            message(STATUS "OpenGL ES 2.0 enabled")
        endif()
    endif()
endif()

# ============================================================================
# Create executable
# ============================================================================
if(WIN32)
    add_executable(${APP_NAME} WIN32 ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES})

elseif(APPLE AND NOT TVOS)
    # macOS bundle
    set(MACOS_RESOURCES sys/posix/res/Valkyrie.icns)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${MACOS_RESOURCES})
        set_source_files_properties(${MACOS_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    endif()

    set(MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME})
    set(MACOSX_BUNDLE_BUNDLE_VERSION 1.0.0)
    set(MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0.0)
    set(MACOSX_BUNDLE_ICON_FILE Valkyrie.icns)

    add_executable(${APP_NAME} MACOSX_BUNDLE ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES} ${MACOS_RESOURCES})

    set_target_properties(${APP_NAME} PROPERTIES
            INSTALL_RPATH "@executable_path/../Frameworks;@loader_path/../Frameworks"
            BUILD_WITH_INSTALL_RPATH TRUE
    )

    # Bundle resources and frameworks
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks
            COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Resources
    )

    # Copy splash image
    if(EXISTS ${CMAKE_SOURCE_DIR}/SamuraiBabel.png)
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${CMAKE_SOURCE_DIR}/SamuraiBabel.png
                $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Resources/
        )
    endif()

    # Sign bundle
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND codesign --force --sign - $<TARGET_BUNDLE_DIR:${APP_NAME}> 2>/dev/null || true
    )

elseif(IS_ANBERNIC)
    # Anbernic executable
    message(STATUS "Creating Anbernic port executable")
    add_executable(${APP_NAME} ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES})

    set_target_properties(${APP_NAME} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/ports"
    )

    # Install to /roms/ports
    install(TARGETS ${APP_NAME} RUNTIME DESTINATION /roms/ports)

    # Create launch script
    file(WRITE "${CMAKE_BINARY_DIR}/ports/${APP_NAME}.sh"
            "#!/bin/bash\n"
            "cd \"$(dirname \"$0\")\"\n"
            "./${APP_NAME}\n")

    install(FILES "${CMAKE_BINARY_DIR}/ports/${APP_NAME}.sh"
            DESTINATION /roms/ports
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_READ WORLD_EXECUTE)

else()
    # Standard Linux executable
    add_executable(${APP_NAME} ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES})
endif()

# ============================================================================
# Link libraries
# ============================================================================
message(STATUS "")
message(STATUS "Linking libraries...")
target_link_libraries(${APP_NAME} PRIVATE ${EXTRA_LIBS})

# Qt6
if(QT6_ENABLED)
    target_link_libraries(${APP_NAME} PRIVATE Qt6::Core Qt6::Gui Qt6::Widgets)
    message(STATUS "  ✓ Qt6 libraries linked")
endif()

# KCC runtime
if(KCC_FOUND AND TARGET KCC::Runtime)
    target_link_libraries(${APP_NAME} PRIVATE KCC::Runtime)
    message(STATUS "  ✓ KCC runtime linked")
endif()

if(KCC_FOUND AND KCC_INCLUDE_DIR)
    target_include_directories(${APP_NAME} PRIVATE ${KCC_INCLUDE_DIR})
endif()

# ============================================================================
# Build Summary
# ============================================================================
message(STATUS "")
message(STATUS "╔═══════════════════════════════════════════════╗")
message(STATUS "║     Valkyrie Engine Build Configuration      ║")
message(STATUS "╠═══════════════════════════════════════════════╣")
message(STATUS "║ Platform: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}")
if(IS_MACOS)
    message(STATUS "║   Type: macOS Desktop                         ║")
elseif(IS_ANBERNIC)
    message(STATUS "║   Type: Anbernic Handheld (Linux ARM64)       ║")
elseif(IS_DESKTOP_LINUX)
    message(STATUS "║   Type: Linux Desktop                         ║")
endif()
message(STATUS "║ Qt6: ${QT6_ENABLED}")
if(USE_SDL3)
    message(STATUS "║ SDL: SDL3                                     ║")
else()
    message(STATUS "║ SDL: SDL2                                     ║")
endif()
message(STATUS "╚═══════════════════════════════════════════════╝")
message(STATUS "")