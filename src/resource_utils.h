//
// Created by Pedro Dias Vicente on 19/10/2025.
//
// Add this to your game_utils.h or a new file like resource_utils.h
#ifndef RESOURCE_UTILS_H
#define RESOURCE_UTILS_H

#include <string>

// Get the correct resource path for the current platform
std::string GetResourcePath(const char* filename);

#endif // RESOURCE_UTILS_H

// Add this to your game_utils.cpp or a new file like resource_utils.cpp
#include <string>
#include <filesystem>

#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#endif

std::string GetResourcePath(const char* filename) {
#ifdef __APPLE__
    // Get the bundle's resource path on macOS
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    if (mainBundle) {
        CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
        if (resourcesURL) {
            char path[PATH_MAX];
            if (CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8*)path, PATH_MAX)) {
                CFRelease(resourcesURL);
                std::string resourcePath = std::string(path) + "/" + filename;

                // Check if file exists in bundle Resources
                if (std::filesystem::exists(resourcePath)) {
                    return resourcePath;
                }
            }
            CFRelease(resourcesURL);
        }
    }
#endif

    // Fallback: check current directory
    if (std::filesystem::exists(filename)) {
        return filename;
    }

    // Fallback: check common directories
    std::vector<std::string> searchPaths = {
        "./",
        "../",
        "../../",
        "./assets/",
        "./res/",
        "../Resources/",
    };

    for (const auto& basePath : searchPaths) {
        std::string fullPath = basePath + filename;
        if (std::filesystem::exists(fullPath)) {
            return fullPath;
        }
    }

    // Return original filename if not found (will fail, but with proper error message)
    return filename;
}

// Usage example - Update your LoadTexture function:
// Instead of:
//   IMG_Load("SamuraiBabel.png")
// Use:
//   IMG_Load(GetResourcePath("SamuraiBabel.png").c_str())