// src/AnbernicConfig.cpp - Anbernic device detection implementation

#include "ANBERNIC_CONFIG.h"
#include <fstream>
#include <algorithm>
#include <cstring>

#ifdef __linux__
#include <sys/utsname.h>
#include <unistd.h>
#endif

AnbernicDevice AnbernicDetector::detectDevice() {
#ifdef __linux__
    // Try multiple detection methods
    AnbernicDevice device = detectFromModel();
    if (device != AnbernicDevice::Unknown) return device;

    device = detectFromDeviceTree();
    if (device != AnbernicDevice::Unknown) return device;

    device = detectFromCpuInfo();
    return device;
#else
    // Not on Linux, can't be an Anbernic device
    return AnbernicDevice::Unknown;
#endif
}

AnbernicDevice AnbernicDetector::detectFromModel() {
#ifdef __linux__
    std::ifstream modelFile("/sys/firmware/devicetree/base/model");
    if (!modelFile.is_open()) return AnbernicDevice::Unknown;

    std::string model;
    std::getline(modelFile, model);
    modelFile.close();

    // Convert to lowercase for easier matching
    std::transform(model.begin(), model.end(), model.begin(), ::tolower);

    if (model.find("rg353p") != std::string::npos) return AnbernicDevice::RG353P;
    if (model.find("rg353v") != std::string::npos) return AnbernicDevice::RG353V;
    if (model.find("rg353m") != std::string::npos) return AnbernicDevice::RG353M;
    if (model.find("rg353ps") != std::string::npos) return AnbernicDevice::RG353PS;
    if (model.find("rg405m") != std::string::npos) return AnbernicDevice::RG405M;
    if (model.find("rg405v") != std::string::npos) return AnbernicDevice::RG405V;
    if (model.find("rg503") != std::string::npos) return AnbernicDevice::RG503;
    if (model.find("rg552") != std::string::npos) return AnbernicDevice::RG552;
    if (model.find("rg35xx-plus") != std::string::npos) return AnbernicDevice::RG35XX_Plus;
    if (model.find("rg35xx-h") != std::string::npos) return AnbernicDevice::RG35XX_H;
    if (model.find("rg35xx") != std::string::npos) return AnbernicDevice::RG35XX;
    if (model.find("rg28xx") != std::string::npos) return AnbernicDevice::RG28XX;
    if (model.find("rg-arc-d") != std::string::npos) return AnbernicDevice::RG_ARC_D;
    if (model.find("rg-arc-s") != std::string::npos) return AnbernicDevice::RG_ARC_S;
#endif

    return AnbernicDevice::Unknown;
}

AnbernicDevice AnbernicDetector::detectFromDeviceTree() {
#ifdef __linux__
    std::ifstream compatFile("/sys/firmware/devicetree/base/compatible");
    if (!compatFile.is_open()) return AnbernicDevice::Unknown;

    std::string compat;
    std::getline(compatFile, compat);
    compatFile.close();

    std::transform(compat.begin(), compat.end(), compat.begin(), ::tolower);

    if (compat.find("anbernic") != std::string::npos) {
        // Check specific models
        if (compat.find("rg353") != std::string::npos) return AnbernicDevice::RG353P;
        if (compat.find("rg503") != std::string::npos) return AnbernicDevice::RG503;
        if (compat.find("rg552") != std::string::npos) return AnbernicDevice::RG552;
    }
#endif

    return AnbernicDevice::Unknown;
}

AnbernicDevice AnbernicDetector::detectFromCpuInfo() {
#ifdef __linux__
    std::ifstream cpuFile("/proc/cpuinfo");
    if (!cpuFile.is_open()) return AnbernicDevice::Unknown;

    std::string line;
    while (std::getline(cpuFile, line)) {
        std::transform(line.begin(), line.end(), line.begin(), ::tolower);

        // Rockchip RK3566 (used in RG353 series)
        if (line.find("rk3566") != std::string::npos) {
            return AnbernicDevice::RG353P; // Default to RG353P
        }
        // Rockchip RK3326 (used in older devices)
        if (line.find("rk3326") != std::string::npos) {
            return AnbernicDevice::RG353P;
        }
    }

    cpuFile.close();
#endif
    return AnbernicDevice::Unknown;
}

bool AnbernicDetector::isAnbernicDevice() {
    return detectDevice() != AnbernicDevice::Unknown;
}

std::string AnbernicDetector::getDeviceName() {
    return getDeviceInfo(detectDevice()).name;
}

AnbernicDeviceInfo AnbernicDetector::getDeviceInfo(AnbernicDevice device) {
    static const std::map<AnbernicDevice, AnbernicDeviceInfo> deviceMap = {
        {AnbernicDevice::RG353P, {AnbernicDevice::RG353P, "Anbernic RG353P", 640, 480, true, true, 2, false, "RK3566"}},
        {AnbernicDevice::RG353V, {AnbernicDevice::RG353V, "Anbernic RG353V", 640, 480, true, true, 2, false, "RK3566"}},
        {AnbernicDevice::RG353M, {AnbernicDevice::RG353M, "Anbernic RG353M", 640, 480, true, true, 2, false, "RK3566"}},
        {AnbernicDevice::RG353PS, {AnbernicDevice::RG353PS, "Anbernic RG353PS", 640, 480, true, true, 2, false, "RK3566"}},
        {AnbernicDevice::RG405M, {AnbernicDevice::RG405M, "Anbernic RG405M", 640, 480, true, true, 2, false, "RK3566"}},
        {AnbernicDevice::RG405V, {AnbernicDevice::RG405V, "Anbernic RG405V", 640, 480, true, true, 2, true, "RK3566"}},
        {AnbernicDevice::RG503, {AnbernicDevice::RG503, "Anbernic RG503", 960, 544, true, true, 2, false, "RK3566"}},
        {AnbernicDevice::RG552, {AnbernicDevice::RG552, "Anbernic RG552", 1920, 1152, true, true, 2, false, "RK3399"}},
        {AnbernicDevice::RG35XX, {AnbernicDevice::RG35XX, "Anbernic RG35XX", 640, 480, false, false, 0, false, "H700"}},
        {AnbernicDevice::RG35XX_Plus, {AnbernicDevice::RG35XX_Plus, "Anbernic RG35XX Plus", 640, 480, true, false, 0, false, "H700"}},
        {AnbernicDevice::RG35XX_H, {AnbernicDevice::RG35XX_H, "Anbernic RG35XX H", 640, 480, true, false, 0, false, "H700"}},
        {AnbernicDevice::RG28XX, {AnbernicDevice::RG28XX, "Anbernic RG28XX", 640, 480, false, false, 0, false, "H700"}},
        {AnbernicDevice::RG_ARC_D, {AnbernicDevice::RG_ARC_D, "Anbernic RG ARC-D", 640, 480, false, true, 1, false, "RK3566"}},
        {AnbernicDevice::RG_ARC_S, {AnbernicDevice::RG_ARC_S, "Anbernic RG ARC-S", 640, 480, false, true, 1, false, "RK3566"}},
        {AnbernicDevice::Unknown, {AnbernicDevice::Unknown, "Unknown Device", 640, 480, false, false, 0, false, "Unknown"}}
    };

    auto it = deviceMap.find(device);
    return (it != deviceMap.end()) ? it->second : deviceMap.at(AnbernicDevice::Unknown);
}