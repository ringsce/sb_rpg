# FindKCC.cmake
# Finds the Kayte C Compiler (KCC) for Samurai Babel RPG
#
# This module will first try to find a system-installed KCC.
# If not found, it will fetch and build KCC from GitHub.
#
# This module defines:
#  KCC_FOUND - System has KCC
#  KCC_EXECUTABLE - The KCC compiler executable
#  KCC_VERSION - The version of KCC
#  KCC_INCLUDE_DIR - The KCC include directory
#  KCC_LIBRARY_DIR - The KCC library directory
#  KCC_LIBRARIES - The KCC runtime libraries
#  KCC::Runtime - Imported library target for KCC runtime
#  kcc_compile_files() - Function to compile .kcc files
#
# Usage:
#   find_package(KCC REQUIRED)
#   if(KCC_FOUND)
#       kcc_compile_files(output_var input_file1 ...)
#   endif()

cmake_minimum_required(VERSION 3.16)
include(FetchContent)
include(FindPackageHandleStandardArgs)

# --- 1. Try to find KCC locally ---

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
        string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" KCC_VERSION "${KCC_VERSION_OUTPUT}")
        if(NOT KCC_VERSION)
            string(REGEX MATCH "[0-9]+\\.[0-9]+" KCC_VERSION "${KCC_VERSION_OUTPUT}")
        endif()
    endif()

    if(NOT KCC_VERSION)
        set(KCC_VERSION "unknown")
    endif()
endif()

if(KCC_RUNTIME_LIBRARY)
    set(KCC_LIBRARIES ${KCC_RUNTIME_LIBRARY})
endif()

# Store find_package arguments
set(_KCC_FIND_QUIETLY ${KCC_FIND_QUIETLY})
set(_KCC_FIND_REQUIRED ${KCC_FIND_REQUIRED})

# Run an initial check to see if local find succeeded
find_package_handle_standard_args(KCC
        REQUIRED_VARS KCC_EXECUTABLE KCC_RUNTIME_LIBRARY
        VERSION_VAR KCC_VERSION
        HANDLE_COMPONENTS
        FAIL_MESSAGE "Could not find Kayte C Compiler (KCC)."
)

set(KCC_FOUND_LOCALLY ${KCC_FOUND})

# --- 2. If not found locally, fetch from GitHub ---

if(NOT KCC_FOUND_LOCALLY)
    if(NOT _KCC_FIND_QUIETLY)
        message(STATUS "KCC not found locally. Fetching from GitHub...")
    endif()

    FetchContent_Declare(
            KCC # Name of the content
            GIT_REPOSITORY https://www.github.com/ringsce/kcc.git
            GIT_TAG main # WARNING: Recommend pinning to a specific commit/tag
    )

    FetchContent_MakeAvailable(KCC)

    # After fetching, check if the required components are now available
    if(TARGET KCC::Runtime)
        set(KCC_FOUND TRUE) # Manually set KCC_FOUND

        if(TARGET KCC::KCC)
            set(KCC_EXECUTABLE $<TARGET_FILE:KCC::KCC>)
        endif()

        set(KCC_RUNTIME_LIBRARY KCC::Runtime) # Use the target name
        set(KCC_LIBRARIES KCC::Runtime)
        get_target_property(KCC_INCLUDE_DIR KCC::Runtime INTERFACE_INCLUDE_DIRECTORIES)

        if(NOT KCC_VERSION AND DEFINED KCC_VERSION)
            # KCC_VERSION might have been set by the subproject
        else()
            set(KCC_VERSION "fetched") # Fallback
        endif()

        if(NOT _KCC_FIND_QUIETLY)
            message(STATUS "Found KCC: Fetched from GitHub (version ${KCC_VERSION})")
            message(STATUS "  KCC include dir: ${KCC_INCLUDE_DIR}")
            message(STATUS "  KCC runtime: ${KCC_RUNTIME_LIBRARY}")
        endif()

    else()
        # Fetching failed or didn't provide required targets
        set(KCC_FOUND FALSE)
    endif()
endif() # End of fetch block

# --- 3. Define local targets (ONLY if found locally) ---

# If KCC was found locally, we must manually create the imported targets
# as they were not created by FetchContent.

if(KCC_FOUND_LOCALLY)

    mark_as_advanced(
            KCC_EXECUTABLE
            KCC_INCLUDE_DIR
            KCC_LIBRARY_DIR
            KCC_RUNTIME_LIBRARY
    )

    if(KCC_FOUND AND NOT TARGET KCC::KCC)
        add_executable(KCC::KCC IMPORTED)
        set_target_properties(KCC::KCC PROPERTIES
                IMPORTED_LOCATION "${KCC_EXECUTABLE}"
        )
    endif()

    if(KCC_RUNTIME_LIBRARY AND NOT TARGET KCC::Runtime)
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

    if(KCC_FOUND AND NOT _KCC_FIND_QUIETLY)
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
endif() # End of KCC_FOUND_LOCALLY block


# --- 4. Define helper functions (if KCC was found) ---

# These functions are now defined if KCC was found either
# locally OR via fetch.

if(KCC_FOUND)
    # Function to compile KCC source files
    if(NOT COMMAND kcc_compile)
        function(kcc_compile OUTPUT_VAR INPUT_FILE)
            if(NOT KCC_EXECUTABLE)
                message(FATAL_ERROR "KCC_EXECUTABLE not set. Cannot compile ${INPUT_FILE}")
            endif()

            set(options VERBOSE)
            set(oneValueArgs OUTPUT_DIR)
            set(multiValueArgs FLAGS INCLUDES DEFINES)
            cmake_parse_arguments(KCC_COMPILE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

            get_filename_component(INPUT_NAME ${INPUT_FILE} NAME_WE)
            get_filename_component(INPUT_EXT ${INPUT_FILE} EXT)

            if(KCC_COMPILE_OUTPUT_DIR)
                set(OUTPUT_FILE "${KCC_COMPILE_OUTPUT_DIR}/${INPUT_NAME}.o")
            else()
                set(OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${INPUT_NAME}.o")
            endif()

            set(COMPILE_FLAGS "")

            foreach(inc ${KCC_COMPILE_INCLUDES})
                list(APPEND COMPILE_FLAGS "-I${inc}")
            endforeach()

            foreach(def ${KCC_COMPILE_DEFINES})
                list(APPEND COMPILE_FLAGS "-D${def}")
            endforeach()

            list(APPEND COMPILE_FLAGS ${KCC_COMPILE_FLAGS})

            add_custom_command(
                    OUTPUT ${OUTPUT_FILE}
                    COMMAND ${KCC_EXECUTABLE} ${COMPILE_FLAGS} -c ${INPUT_FILE} -o ${OUTPUT_FILE}
                    DEPENDS ${INPUT_FILE}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMENT "Compiling KCC source: ${INPUT_FILE}"
                    VERBATIM
            )

            set(${OUTPUT_VAR} ${OUTPUT_FILE} PARENT_SCOPE)
        endfunction()
    endif()

    # Function to compile multiple KCC files
    if(NOT COMMAND kcc_compile_files)
        function(kcc_compile_files OUTPUT_VAR)
            set(OUTPUT_FILES "")

            foreach(input_file ${ARGN})
                kcc_compile(compiled_file ${input_file})
                list(APPEND OUTPUT_FILES ${compiled_file})
            endforeach()

            set(${OUTPUT_VAR} ${OUTPUT_FILES} PARENT_SCOPE)
        endfunction()
    endif()
endif() # End of if(KCC_FOUND)


# --- 5. Final failure check ---

if(NOT KCC_FOUND AND _KCC_FIND_REQUIRED)
    message(FATAL_ERROR "Could not find or fetch KCC. Set KCC_ROOT, install KCC, or check network access.")
endif()