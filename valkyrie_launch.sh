#!/bin/bash
# Valkyrie Engine Launch Script for Anbernic Devices
# Compatible with ArkOS, JELOS, AmberELEC, and other CFWs

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Detect CFW type
CFW="Unknown"
if [ -f "/etc/os-release" ]; then
    . /etc/os-release
    case "$NAME" in
        *"ArkOS"*)
            CFW="ArkOS"
            ;;
        *"JELOS"*)
            CFW="JELOS"
            ;;
        *"AmberELEC"*)
            CFW="AmberELEC"
            ;;
        *"RetroOZ"*)
            CFW="RetroOZ"
            ;;
    esac
fi

echo "Valkyrie Engine - Samurai Babel MMO RPG"
echo "CFW Detected: $CFW"
echo "Starting..."

# Set up environment
export SDL_GAMECONTROLLERCONFIG_FILE="$SCRIPT_DIR/gamecontrollerdb.txt"
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Set performance governor to performance mode (if available)
if [ -w "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    echo "Setting CPU governor to performance mode..."
    echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
fi

# Check if executable exists
if [ ! -f "./Valkyrie" ]; then
    echo "Error: Valkyrie executable not found!"
    sleep 3
    exit 1
fi

# Make sure it's executable
chmod +x ./Valkyrie

# Run the game
./Valkyrie

# Restore CPU governor after exit
if [ -w "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    echo "Restoring CPU governor..."
    echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
fi

echo "Valkyrie Engine closed"
exit 0
