# FindSDL3.cmake - Locate SDL3
#
# This module defines:
#   SDL3_FOUND        - True if SDL3 was found
#   SDL3_INCLUDE_DIRS - Where to find SDL3/SDL.h
#   SDL3_LIBRARIES    - The SDL3 library to link against

find_path(SDL3_INCLUDE_DIR SDL3/SDL.h
    HINTS
        ENV SDL3_DIR
        /opt/homebrew/include
        /usr/local/include
        /usr/include
    PATH_SUFFIXES SDL3
)

find_library(SDL3_LIBRARY NAMES SDL3
    HINTS
        ENV SDL3_DIR
        /opt/homebrew/lib
        /usr/local/lib
        /usr/lib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDL3 DEFAULT_MSG SDL3_INCLUDE_DIR SDL3_LIBRARY)

if(SDL3_FOUND)
    set(SDL3_INCLUDE_DIRS ${SDL3_INCLUDE_DIR})
    set(SDL3_LIBRARIES ${SDL3_LIBRARY})
endif()

