#!/bin/bash

# Script to copy SamuraiBabel.png to the macOS app bundle Resources directory

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Searching for SamuraiBabel.png..."

# Define the project root (assuming script is run from build directory or project root)
if [ -d "../build" ]; then
    PROJECT_ROOT="."
    BUILD_DIR="./build"
elif [ -d "./build" ]; then
    PROJECT_ROOT="."
    BUILD_DIR="./build"
else
    PROJECT_ROOT=".."
    BUILD_DIR="../build"
fi

# Target directory
BUNDLE_RESOURCES="$BUILD_DIR/Valkyrie.app/Contents/Resources"

# Create Resources directory if it doesn't exist
mkdir -p "$BUNDLE_RESOURCES"

# Search for SamuraiBabel.png in common locations
SEARCH_PATHS=(
    "$PROJECT_ROOT/SamuraiBabel.png"
    "$PROJECT_ROOT/assets/SamuraiBabel.png"
    "$PROJECT_ROOT/res/SamuraiBabel.png"
    "$PROJECT_ROOT/resources/SamuraiBabel.png"
    "$PROJECT_ROOT/img/SamuraiBabel.png"
    "$PROJECT_ROOT/images/SamuraiBabel.png"
)

FOUND=0

for path in "${SEARCH_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo -e "${GREEN}Found:${NC} $path"
        cp "$path" "$BUNDLE_RESOURCES/"
        echo -e "${GREEN}Copied to:${NC} $BUNDLE_RESOURCES/SamuraiBabel.png"
        FOUND=1
        break
    fi
done

# If not found in common locations, do a recursive search
if [ $FOUND -eq 0 ]; then
    echo -e "${YELLOW}Not found in common locations. Searching recursively...${NC}"
    FOUND_FILE=$(find "$PROJECT_ROOT" -name "SamuraiBabel.png" -type f | head -1)

    if [ -n "$FOUND_FILE" ]; then
        echo -e "${GREEN}Found:${NC} $FOUND_FILE"
        cp "$FOUND_FILE" "$BUNDLE_RESOURCES/"
        echo -e "${GREEN}Copied to:${NC} $BUNDLE_RESOURCES/SamuraiBabel.png"
        FOUND=1
    fi
fi

if [ $FOUND -eq 0 ]; then
    echo -e "${RED}Error: SamuraiBabel.png not found in project!${NC}"
    echo "Please place the file in one of these locations:"
    echo "  - Project root"
    echo "  - assets/"
    echo "  - res/"
    echo "  - resources/"
    exit 1
fi

# Also copy any other PNG/JPG files found in common asset directories
echo ""
echo "Copying additional assets..."

for dir in "assets" "res" "resources" "img" "images"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        # Copy PNG files
        for ext in png PNG; do
            for file in "$PROJECT_ROOT/$dir"/*.$ext; do
                if [ -f "$file" ]; then
                    basename_file=$(basename "$file")
                    cp "$file" "$BUNDLE_RESOURCES/"
                    echo -e "${GREEN}Copied:${NC} $basename_file"
                fi
            done
        done
        # Copy JPG/JPEG files
        for ext in jpg jpeg JPG JPEG; do
            for file in "$PROJECT_ROOT/$dir"/*.$ext; do
                if [ -f "$file" ]; then
                    basename_file=$(basename "$file")
                    cp "$file" "$BUNDLE_RESOURCES/"
                    echo -e "${GREEN}Copied:${NC} $basename_file"
                fi
            done
        done
    fi
done

echo ""
echo -e "${GREEN}Done!${NC} Resources copied to bundle."
echo "You can now run: lldb build/Valkyrie.app"