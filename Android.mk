# Android.mk for building ARM64 libraries using the Android NDK
# This is a simplified example, and you may need to modify it to suit your specific needs.

# Define the platform name
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    TARGET_PLATFORM = android
else
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Set up the build environment
ifeq ($(host.build_type), release)
    CXXFLAGS += -fobjc-arc -g -std=c++11
else
    CXXFLAGS += -fobjc-arc
endif

CXXLDFLAGS = -l SDL2
CXXLDLIBS = -ldl

# Set up the compiler flags
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    CC = clang
    CXX = clang++
else
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Define the output directory for the library
OUTPUT_DIR = libSDL2_arm64_$(TARGET_PLATFORM)

# Define the source files for the library
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    LIBS += -l SDL2
LIBS += -l GLU
LIBS += -l OpenGL
else
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Define the include directories for the library
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    INCLUDES += -I /usr/include/c++/$(CXXVersion)/x86_64-pc-linux-gnu
ELSE
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Define the link flags for the library
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    LDFLAGS += -Wl,-z,--strip-all
LDFLAGS += -static-layers
ELSE
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Define the libraries to link against
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    LIBS += -lsdl2
LIBS += -lGLU
LIBS += -lopengl32
ELSE
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Define the dependencies for the library
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    DEPS += libGLU.a libOpenGL.a
ELSE
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

# Compile and link the library
$(call compile, $(CXXLDFLAGS), $(CXXLDLIBS), $(CXXFLAGS)))

# Link against the libraries specified in the output directory
ifeq ($(HOST(platform)),$(TARGETPlatformAndroid))
    LD = ld -lSDL2 -lGLU -lopengl32
else
    echo "Unsupported platform: $(HOST(platform))."
    exit 1
fi

$(call link, $(LDFLAGS), $(LD), $(OUTPUT_DIR))
