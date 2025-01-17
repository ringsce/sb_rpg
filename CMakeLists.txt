cmake_minimum_required(VERSION 3.15)

# Set the project name
project(CrossPlatformApp LANGUAGES CXX)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define source files
set(SOURCES
    ai.cpp
    camera.cpp
    gamepad.cpp
    main.cpp
)

# Define include directories
include_directories(
    ${CMAKE_SOURCE_DIR}
    /opt/homebrew/include
)

# Platform-specific configurations
if(ANDROID)
    message(STATUS "Configuring for Android")
    set(CMAKE_SYSTEM_NAME Android)
    set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)
    set(CMAKE_ANDROID_NDK $ENV{ANDROID_NDK_HOME})
    set(CMAKE_ANDROID_STL_TYPE c++_static)
    set(CMAKE_ANDROID_PLATFORM android-21)
    include_directories(${CMAKE_SOURCE_DIR}/libs/SDL2/include)
    add_definitions(-DGL_ES)

    # Link libraries for Android
    set(LINK_LIBRARIES
        SDL2
        GLESv2
        EGL
    )
elseif(APPLE)
    message(STATUS "Configuring for macOS")
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    find_library(SDL2 SDL2)
    find_library(SDL2_image SDL2_image)
    find_library(OpenGL OpenGL)
    find_library(Metal Metal)
    find_library(QuartzCore QuartzCore)

    # Link libraries for macOS
    set(LINK_LIBRARIES
        ${SDL2}
        ${SDL2_image}
        ${OpenGL}
        ${Metal}
        ${QuartzCore}
    )
elseif(WIN32)
    message(STATUS "Configuring for Windows")
    include_directories(C:/path/to/SDL2/include)
    link_directories(C:/path/to/SDL2/lib)

    # Link libraries for Windows
    set(LINK_LIBRARIES
        SDL2
        opengl32
    )
elseif(UNIX)
    message(STATUS "Configuring for Linux")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a")
    include_directories(/usr/include/SDL2)

    # Link libraries for Linux
    set(LINK_LIBRARIES
        SDL2
        GL
        EGL
    )
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

# Add the executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Link the platform-specific libraries
target_link_libraries(${PROJECT_NAME} ${LINK_LIBRARIES})

# Deployment target configuration for Apple platforms
if(APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_DEPLOYMENT_TARGET "11.0"
    )
endif()

# Android-specific deployment settings
if(ANDROID)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        ANDROID_NATIVE_LIB_DIR ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
    )
endif()

