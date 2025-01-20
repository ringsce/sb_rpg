# Cross-compiler and tools
CC = aros-ppc-gcc # Replace with your AROS cross-compiler
AR = aros-ppc-ar
RANLIB = aros-ppc-ranlib

# Compiler and linker flags
CFLAGS = -Wall -Wextra -std=c99 -fpic -I$(AROS_INCLUDE_DIR)
LDFLAGS = -shared

# Library name and build paths
LIB_NAME = kayte.library
SRCS = kayte.c
OBJS = $(SRCS:.c=.o)
AROS_LIB_DIR = /path/to/aros/libs # Replace with the actual AROS library directory

# Phony targets
.PHONY: all clean install

# Default target: build the library
all: $(LIB_NAME)

# Build the shared library
$(LIB_NAME): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Compile source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up build artifacts
clean:
	rm -f $(OBJS) $(LIB_NAME)

# Install the library into the AROS library directory
install: $(LIB_NAME)
	cp $(LIB_NAME) $(AROS_LIB_DIR)
