# FindSDL2.cmake - Locate SDL2
#
# This module defines:
#   SDL2_FOUND        - True if SDL2 was found
#   SDL2_INCLUDE_DIRS - Where to find SDL2/SDL.h
#   SDL2_LIBRARIES    - The SDL2 library to link against

find_path(SDL2_INCLUDE_DIR SDL2/SDL.h
    HINTS
        ENV SDL2_DIR
        /opt/homebrew/include
        /usr/local/include
        /usr/include
    PATH_SUFFIXES SDL2
)

find_library(SDL2_LIBRARY NAMES SDL2
    HINTS
        ENV SDL2_DIR
        /opt/homebrew/lib
        /usr/local/lib
        /usr/lib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDL2 DEFAULT_MSG SDL2_INCLUDE_DIR SDL2_LIBRARY)

if(SDL2_FOUND)
    set(SDL2_INCLUDE_DIRS ${SDL2_INCLUDE_DIR})
    set(SDL2_LIBRARIES ${SDL2_LIBRARY})
endif()

