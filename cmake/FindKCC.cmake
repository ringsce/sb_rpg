# FindKCC.cmake
# Finds the Kayte C Compiler (KCC) for Samurai Babel RPG
#
# This module defines:
#  KCC_FOUND - System has KCC
#  KCC_EXECUTABLE - The KCC compiler executable
#  KCC_VERSION - The version of KCC
#  KCC_INCLUDE_DIR - The KCC include directory
#  KCC_LIBRARY_DIR - The KCC library directory
#  KCC_LIBRARIES - The KCC runtime libraries
#
# Usage:
#   find_package(KCC REQUIRED)
#   if(KCC_FOUND)
#       kcc_compile(output_file input_file)
#   endif()

cmake_minimum_required(VERSION 3.16)

# Set paths to search for KCC
set(KCC_SEARCH_PATHS
        ${KCC_ROOT}
        $ENV{KCC_ROOT}
        $ENV{KCC_HOME}
        /usr/local/kcc
        /opt/kcc
        /opt/homebrew/opt/kcc
        ~/kcc
        ${CMAKE_SOURCE_DIR}/tools/kcc
        ${CMAKE_SOURCE_DIR}/external/kcc
        ${CMAKE_SOURCE_DIR}/vendor/kcc
)

# Find KCC executable
find_program(KCC_EXECUTABLE
        NAMES kcc kayte-cc kaytec
        PATHS ${KCC_SEARCH_PATHS}
        PATH_SUFFIXES bin
        DOC "Path to the Kayte C Compiler executable"
)

# Find KCC include directory
find_path(KCC_INCLUDE_DIR
        NAMES kcc/runtime.h kayte/runtime.h kcc.h
        PATHS ${KCC_SEARCH_PATHS}
        PATH_SUFFIXES include include/kcc
        DOC "Path to KCC include directory"
)

# Find KCC library directory
find_path(KCC_LIBRARY_DIR
        NAMES libkcc.a libkcc.dylib libkcc.so kcc.lib
        PATHS ${KCC_SEARCH_PATHS}
        PATH_SUFFIXES lib lib64 lib/kcc
        DOC "Path to KCC library directory"
)

# Find KCC runtime library
find_library(KCC_RUNTIME_LIBRARY
        NAMES kcc kcc_runtime kayte_runtime
        PATHS ${KCC_SEARCH_PATHS}
        PATH_SUFFIXES lib lib64 lib/kcc
        DOC "KCC runtime library"
)

# Get KCC version if executable found
if(KCC_EXECUTABLE)
    execute_process(
            COMMAND ${KCC_EXECUTABLE} --version
            OUTPUT_VARIABLE KCC_VERSION_OUTPUT
            ERROR_VARIABLE KCC_VERSION_ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE KCC_VERSION_RESULT
    )

    if(KCC_VERSION_RESULT EQUAL 0)
        # Try to extract version from output
        string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" KCC_VERSION "${KCC_VERSION_OUTPUT}")
        if(NOT KCC_VERSION)
            string(REGEX MATCH "[0-9]+\\.[0-9]+" KCC_VERSION "${KCC_VERSION_OUTPUT}")
        endif()
    endif()

    if(NOT KCC_VERSION)
        set(KCC_VERSION "unknown")
    endif()
endif()

# Set KCC_LIBRARIES
if(KCC_RUNTIME_LIBRARY)
    set(KCC_LIBRARIES ${KCC_RUNTIME_LIBRARY})
endif()

# Handle REQUIRED and QUIET arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(KCC
        REQUIRED_VARS KCC_EXECUTABLE
        VERSION_VAR KCC_VERSION
        FAIL_MESSAGE "Could not find Kayte C Compiler (KCC). Set KCC_ROOT to the installation directory."
)

# Mark variables as advanced
mark_as_advanced(
        KCC_EXECUTABLE
        KCC_INCLUDE_DIR
        KCC_LIBRARY_DIR
        KCC_RUNTIME_LIBRARY
)

# Create imported target if found
if(KCC_FOUND AND NOT TARGET KCC::KCC)
    add_executable(KCC::KCC IMPORTED)
    set_target_properties(KCC::KCC PROPERTIES
            IMPORTED_LOCATION "${KCC_EXECUTABLE}"
    )

    # Create interface library for runtime
    if(KCC_RUNTIME_LIBRARY)
        add_library(KCC::Runtime UNKNOWN IMPORTED)
        set_target_properties(KCC::Runtime PROPERTIES
                IMPORTED_LOCATION "${KCC_RUNTIME_LIBRARY}"
        )
        if(KCC_INCLUDE_DIR)
            set_target_properties(KCC::Runtime PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${KCC_INCLUDE_DIR}"
            )
        endif()
    endif()
endif()

# Function to compile KCC source files
function(kcc_compile OUTPUT_VAR INPUT_FILE)
    if(NOT KCC_FOUND)
        message(FATAL_ERROR "KCC not found. Cannot compile ${INPUT_FILE}")
    endif()

    # Parse optional arguments
    set(options VERBOSE)
    set(oneValueArgs OUTPUT_DIR)
    set(multiValueArgs FLAGS INCLUDES DEFINES)
    cmake_parse_arguments(KCC_COMPILE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Get input file name without extension
    get_filename_component(INPUT_NAME ${INPUT_FILE} NAME_WE)
    get_filename_component(INPUT_EXT ${INPUT_FILE} EXT)

    # Set output file
    if(KCC_COMPILE_OUTPUT_DIR)
        set(OUTPUT_FILE "${KCC_COMPILE_OUTPUT_DIR}/${INPUT_NAME}.o")
    else()
        set(OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${INPUT_NAME}.o")
    endif()

    # Build compiler flags
    set(COMPILE_FLAGS "")

    # Add includes
    foreach(inc ${KCC_COMPILE_INCLUDES})
        list(APPEND COMPILE_FLAGS "-I${inc}")
    endforeach()

    # Add defines
    foreach(def ${KCC_COMPILE_DEFINES})
        list(APPEND COMPILE_FLAGS "-D${def}")
    endforeach()

    # Add user flags
    list(APPEND COMPILE_FLAGS ${KCC_COMPILE_FLAGS})

    # Add custom command to compile
    add_custom_command(
            OUTPUT ${OUTPUT_FILE}
            COMMAND ${KCC_EXECUTABLE} ${COMPILE_FLAGS} -c ${INPUT_FILE} -o ${OUTPUT_FILE}
            DEPENDS ${INPUT_FILE}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Compiling KCC source: ${INPUT_FILE}"
            VERBATIM
    )

    # Return output file
    set(${OUTPUT_VAR} ${OUTPUT_FILE} PARENT_SCOPE)
endfunction()

# Function to compile multiple KCC files
function(kcc_compile_files OUTPUT_VAR)
    set(OUTPUT_FILES "")

    foreach(input_file ${ARGN})
        kcc_compile(compiled_file ${input_file})
        list(APPEND OUTPUT_FILES ${compiled_file})
    endforeach()

    set(${OUTPUT_VAR} ${OUTPUT_FILES} PARENT_SCOPE)
endfunction()

# Print status if found
if(KCC_FOUND)
    message(STATUS "Found KCC: ${KCC_EXECUTABLE} (version ${KCC_VERSION})")
    if(KCC_INCLUDE_DIR)
        message(STATUS "  KCC include dir: ${KCC_INCLUDE_DIR}")
    endif()
    if(KCC_LIBRARY_DIR)
        message(STATUS "  KCC library dir: ${KCC_LIBRARY_DIR}")
    endif()
    if(KCC_RUNTIME_LIBRARY)
        message(STATUS "  KCC runtime: ${KCC_RUNTIME_LIBRARY}")
    endif()
endif()