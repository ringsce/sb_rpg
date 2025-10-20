//
// Created by Pedro Dias Vicente on 20/10/2025.
//

// ============================================================================
// AnbernicConfig.h - Anbernic device detection and configuration
// ============================================================================

#ifndef ANBERNIC_CONFIG_H
#define ANBERNIC_CONFIG_H

#include <string>
#include <map>

enum class AnbernicDevice {
    Unknown,
    RG353P,      // 3.5" 640x480
    RG353V,      // 3.5" 640x480 vertical
    RG353M,      // 3.5" 640x480 metal
    RG353PS,     // 3.5" 640x480
    RG405M,      // 4.0" 640x480
    RG405V,      // 4.0" 640x480 vertical
    RG503,       // 5.0" 960x544
    RG552,       // 5.36" 1920x1152
    RG35XX,      // 3.5" 640x480
    RG35XX_Plus, // 3.5" 640x480
    RG35XX_H,    // 3.5" 640x480 horizontal
    RG28XX,      // 2.8" 640x480
    RG_ARC_D,    // 3.5" 640x480
    RG_ARC_S     // 3.5" 640x480
};

struct AnbernicDeviceInfo {
    AnbernicDevice device;
    std::string name;
    int screenWidth;
    int screenHeight;
    bool hasWifi;
    bool hasAnalogSticks;
    int analogStickCount;
    bool touchScreen;
    std::string cpu;
};

class AnbernicDetector {
public:
    static AnbernicDevice detectDevice();
    static AnbernicDeviceInfo getDeviceInfo(AnbernicDevice device);
    static bool isAnbernicDevice();
    static std::string getDeviceName();

private:
    static AnbernicDevice detectFromCpuInfo();
    static AnbernicDevice detectFromDeviceTree();
    static AnbernicDevice detectFromModel();
};

#endif // ANBERNIC_CONFIG_H
