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
option(USE_SDL3                  "Use SDL3 instead of SDL2 if available" ON)
option(USE_KCC                   "Use Kayte C Compiler for game scripts" ON) # <-- SET TO ON

if(USE_MoltenVK)
    add_definitions(-DUSE_MOLTENVK)
endif()

# Find KCC (Kayte C Compiler) for game scripts
if(USE_KCC)
    # This will now use your cmake/FindKCC.cmake module
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
        message(WARNING "KCC not found and failed to fetch/configure.")
        message(WARNING "Building without KCC script support.")
    endif()
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

# Add KCC compiled objects if available
if(KCC_FOUND AND KCC_COMPILED_OBJECTS)
    list(APPEND VALKYRIE_SOURCES ${KCC_COMPILED_OBJECTS})
    message(STATUS "Added ${CMAKE_CURRENT_LIST_LENGTH} KCC compiled objects to build")
endif()

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
    # Note: SDL3_image is not standard yet, assuming SDL2_image for now
    find_package(SDL2_image REQUIRED)
    include_directories(${SDL2_IMAGE_INCLUDE_DIRS})
    list(APPEND EXTRA_LIBS ${SDL2_IMAGE_LIBRARIES})
else()
    find_package(SDL2 REQUIRED)
    include_directories(${SDL2_INCLUDE_DIRS})
    list(APPEND EXTRA_LIBS ${SDL2_LIBRARIES})

    find_package(SDL2_image REQUIRED)
    include_directories(${SDL2_IMAGE_INCLUDE_DIRS})
    list(APPEND EXTRA_LIBS ${SDL2_IMAGE_LIBRARIES})
endif()


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

    if(USE_MoltenVK)
        message(STATUS "Using MoltenVK as Vulkan backend")

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

    # Find and link Apple frameworks
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
    find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)

    # Find libcurl
    find_package(CURL REQUIRED)
    include_directories(${CURL_INCLUDE_DIRS})

    list(APPEND EXTRA_LIBS
            ${METAL_FRAMEWORK}
            ${METALKIT_FRAMEWORK}
            ${FOUNDATION_FRAMEWORK}
            ${QUARTZCORE_FRAMEWORK}
            ${CURL_LIBRARIES}
    )

elseif(ANDROID)
    # ... (ANDROID section unchanged) ...
elseif(UNIX AND NOT APPLE)
    # ... (UNIX section unchanged) ...
endif()

# Optional OpenAL
if(OPENAL)
    # ... (OpenAL section unchanged) ...
endif()

# Optional Vulkan support
if(USE_VULKAN)
    add_dependencies(${APP_NAME} nvrhi_vk)
endif()

# Create executable - single unified location
if(WIN32)
    # ... (WIN32 executable section unchanged) ...

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

    set_target_properties(${APP_NAME} PROPERTIES
            INSTALL_RPATH "@executable_path/../Frameworks;@loader_path/../Frameworks"
            BUILD_WITH_INSTALL_RPATH TRUE
    )

    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks
            COMMENT "Creating Frameworks directory"
    )

    # --- IMPROVED: Check for SDL2 as framework ---
    if(EXISTS ${SDL2_LIBRARY} AND IS_DIRECTORY ${SDL2_LIBRARY})
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${SDL2_LIBRARY}
                $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/SDL2.framework
                COMMAND chmod -R u+w $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/SDL2.framework 2>/dev/null || true
                COMMENT "Copying SDL2 framework"
        )
    elseif(EXISTS ${SDL2_LIBRARY}) # Copy as a .dylib
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${SDL2_LIBRARY}
                $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/
                COMMENT "Copying SDL2 library"
        )
    endif()

    # --- IMPROVED: Check for SDL2_image as framework ---
    if(EXISTS ${SDL2_IMAGE_LIBRARY} AND IS_DIRECTORY ${SDL2_IMAGE_LIBRARY})
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${SDL2_IMAGE_LIBRARY}
                $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/SDL2_image.framework
                COMMAND chmod -R u+w $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/SDL2_image.framework 2>/dev/null || true
                COMMENT "Copying SDL2_image framework"
        )
    elseif(EXISTS ${SDL2_IMAGE_LIBRARY}) # Copy as a .dylib
        add_custom_command(TARGET ${APP_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${SDL2_IMAGE_LIBRARY}
                $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/
                COMMENT "Copying SDL2_image library"
        )
    endif()

    # Fix permissions and remove quarantine attributes
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
            COMMAND chmod -R u+w $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/ 2>/dev/null || true
            COMMAND xattr -cr $<TARGET_BUNDLE_CONTENT_DIR:${APP_NAME}>/Frameworks/ 2>/dev/null || true
            COMMAND xattr -cr $<TARGET_BUNDLE_DIR:${APP_NAME}> 2>/dev/null || true
            COMMENT "Fixing permissions and removing quarantine"
    )

    # Sign frameworks and libraries
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

# Link KCC runtime if available
if(KCC_FOUND AND TARGET KCC::Runtime)
    target_link_libraries(${APP_NAME} PRIVATE KCC::Runtime)
    message(STATUS "Linked KCC runtime library to ${APP_NAME}")
endif()

# Add KCC include directory if available
if(KCC_FOUND AND KCC_INCLUDE_DIR)
    target_include_directories(${APP_NAME} PRIVATE ${KCC_INCLUDE_DIR})
endif()

# MSVC Studio settings
if(MSVC)
    set(CMAKE_SYSTEM_VERSION 10.0.22621.0) # Windows 11 SDK
endif()