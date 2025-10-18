cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

# Set application name
if(NOT DEFINED APP_NAME)
    set(APP_NAME Valkyrie)
endif()
project(${APP_NAME})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set macOS deployment target
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0")

    # Detect and set architecture
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64" OR CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "arm64")
        set(CMAKE_OSX_ARCHITECTURES "arm64")
        message(STATUS "Building for Apple Silicon (arm64)")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64" OR CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64")
        message(STATUS "Building for Intel Mac (x86_64)")
    else()
        # Build universal binary if architecture not detected
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
option(USE_SDL3                  "Use SDL3 instead of SDL2 if available" ON)

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
        srv/serverRegistration.h
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

    # Find and link Apple frameworks (must use find_library for frameworks)
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
    find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)

    # SDL linking
    find_library(SDL2_LIBRARY SDL2 PATHS /opt/homebrew/lib REQUIRED)
    find_library(SDL2_IMAGE_LIBRARY SDL2_image PATHS /opt/homebrew/lib REQUIRED)

    # Find libcurl
    find_package(CURL REQUIRED)
    include_directories(${CURL_INCLUDE_DIRS})

    list(APPEND EXTRA_LIBS
            ${SDL2_LIBRARY}
            ${SDL2_IMAGE_LIBRARY}
            ${METAL_FRAMEWORK}
            ${METALKIT_FRAMEWORK}
            ${FOUNDATION_FRAMEWORK}
            ${QUARTZCORE_FRAMEWORK}
            ${CURL_LIBRARIES}
    )

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

# Create executable - single unified location
if(WIN32)
    message(STATUS "Configuring for Windows...")
    add_definitions(-DPLATFORM_WINDOWS)

    # Optional: Set Windows 11 compatibility manifest
    set(WIN32_MANIFEST "${CMAKE_SOURCE_DIR}/sys/windows/app.manifest")
    if(EXISTS ${WIN32_MANIFEST})
        set_source_files_properties(${WIN32_MANIFEST} PROPERTIES HEADER_FILE_ONLY TRUE)
    endif()

    # Set executable to be a Windows GUI app (no console)
    add_executable(${APP_NAME} WIN32 ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES} ${WIN32_MANIFEST})

    # Link DirectX libraries
    find_library(DXGI_LIBRARY dxgi)
    find_library(D3D12_LIBRARY d3d12)
    if(DXGI_LIBRARY AND D3D12_LIBRARY)
        list(APPEND EXTRA_LIBS ${DXGI_LIBRARY} ${D3D12_LIBRARY})
    endif()

elseif(APPLE AND NOT TVOS)
    # macOS bundle configuration
    set(MACOS_RESOURCES sys/posix/res/Valkyrie.icns)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${MACOS_RESOURCES})
        set_source_files_properties(${MACOS_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    endif()

    set(MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME})
    set(MACOSX_BUNDLE_BUNDLE_VERSION 1.0.0)
    set(MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0.0)
    set(MACOSX_BUNDLE_ICON_FILE Valkyrie.icns)

    add_executable(${APP_NAME} MACOSX_BUNDLE ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES} ${MACOS_RESOURCES})

    # Set rpath to look in the app bundle
    set_target_properties(${APP_NAME} PROPERTIES
            INSTALL_RPATH "@executable_path/../Frameworks;@loader_path/../Frameworks"
            BUILD_WITH_INSTALL_RPATH TRUE
    )

    # Create Frameworks directory
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks
            COMMENT "Creating Frameworks directory"
    )

    # Copy SDL2 framework if it exists
    if(EXISTS ${SDL2_LIBRARY} AND IS_DIRECTORY ${SDL2_LIBRARY})
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${SDL2_LIBRARY}
                $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/SDL2.framework
                COMMAND chmod -R u+w $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/SDL2.framework 2>/dev/null || true
                COMMENT "Copying SDL2 framework"
        )
    endif()

    # Copy SDL2_image library
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${SDL2_IMAGE_LIBRARY}
            $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/
            COMMENT "Copying SDL2_image library"
    )

    # Fix permissions and remove quarantine attributes
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND chmod -R u+w $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/ 2>/dev/null || true
            COMMAND xattr -cr $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/ 2>/dev/null || true
            COMMAND xattr -cr $<TARGET_BUNDLE_DIR:${APP_NAME}> 2>/dev/null || true
            COMMENT "Fixing permissions and removing quarantine"
    )

    # Sign frameworks and libraries using find command
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND find $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks -name "*.dylib" -exec codesign --force --sign - {} \\$<SEMICOLON> 2>/dev/null || true
            COMMAND find $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks -name "*.framework" -type d -maxdepth 1 -exec codesign --force --deep --sign - {} \\$<SEMICOLON> 2>/dev/null || true
            COMMENT "Signing embedded frameworks and libraries"
    )

    # Finally sign the main app bundle
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND codesign --force --sign - $<TARGET_BUNDLE_DIR:${APP_NAME}> 2>/dev/null || true
            COMMENT "Signing app bundle"
    )
else()
    # Default executable for Linux, Android, tvOS, etc.
    add_executable(${APP_NAME} ${VALKYRIE_SOURCES} ${VALKYRIE_INCLUDES})
endif()

# Link all collected libraries
target_link_libraries(${APP_NAME} PRIVATE ${EXTRA_LIBS})

# MSVC Studio settings
if(MSVC)
    set(CMAKE_SYSTEM_VERSION 10.0.22621.0) # Windows 11 SDK
endif()