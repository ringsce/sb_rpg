// main.cpp - Conditional compilation for Qt6 + SDL2 or standalone SDL2

#ifdef USE_QT6
    // Qt6 + SDL2 Integration (macOS and Desktop Linux)
    #include <QApplication>
    #include "MainWindow.h"
#include "ANBERNIC_CONFIG.h"
#include <iostream>

    int main(int argc, char *argv[]) {
        // Detect platform
        AnbernicDevice device = AnbernicDetector::detectDevice();
        
        if (device != AnbernicDevice::Unknown) {
            std::cout << "Running on Anbernic device: " 
                      << AnbernicDetector::getDeviceName() << std::endl;
        }
        
        QApplication app(argc, argv);
        app.setApplicationName("Valkyrie Engine");
        app.setApplicationVersion("1.0.0");
        
        MainWindow window;
        window.show();
        
        return app.exec();
    }

#else
    // Standalone SDL2 (Anbernic devices without Qt6 or legacy mode)
    #include <SDL2/SDL.h>
    #include <SDL2/SDL_image.h>
    #include <iostream>
    #include "game_utils.h"
    #include "srv/serverRegistration.h"
    #include "src/ANBERNIC_CONFIG.h"
    #include "src/gamepad.h"

    // Platform-specific includes for cross-platform support
    #if defined(__ANDROID__)
    #include <GLES2/gl2.h>  // OpenGL ES for Android

    #elif defined(__APPLE__) && !defined(__IOS__)
    #include <OpenGL/gl.h>  // OpenGL for macOS
    #include <OpenGL/glu.h>
    #define GL_SILENCE_DEPRECATION

    #elif defined(__IOS__)
    #include <OpenGLES/ES2/gl.h>  // OpenGL ES for iOS

    #elif defined(__linux__) && defined(__aarch64__)
    #include <GLES2/gl2.h>  // OpenGL ES for Linux ARM64

    #elif defined(__linux__) && defined(__x86_64__)
    #include <GL/gl.h>  // OpenGL for Linux AMD64
    #include <GL/glu.h>

    #elif defined(__linux__) && defined(__i386__)
    #include <GL/gl.h>  // OpenGL for Linux x86
    #include <GL/glu.h>

    #elif defined(_WIN32) && defined(_M_X64)
    #include <GL/gl.h>  // OpenGL for Windows AMD64
    #include <GL/glu.h>

    #elif defined(_WIN32) && defined(_M_IX86)
    #include <GL/gl.h>  // OpenGL for Windows x86
    #include <GL/glu.h>

    #endif

    struct Button {
        int x, y;
        int width, height;
        SDL_Color color;
    };

    bool InitializeSDL(SDL_Window** window, SDL_GLContext* glContext, const char* title, int width, int height) {
        if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK) != 0) {
            std::cerr << "Error initializing SDL: " << SDL_GetError() << std::endl;
            return false;
        }

        if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG)) {
            std::cerr << "Error initializing SDL_image: " << IMG_GetError() << std::endl;
            SDL_Quit();
            return false;
        }

        *window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
                                   SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
        if (!*window) {
            std::cerr << "Error creating window: " << SDL_GetError() << std::endl;
            return false;
        }

        *glContext = SDL_GL_CreateContext(*window);
        if (!*glContext) {
            std::cerr << "Error creating GL context: " << SDL_GetError() << std::endl;
            SDL_DestroyWindow(*window);
            return false;
        }

        return true;
    }

    int main(int argc, char* argv[]) {
        // Detect Anbernic device
        AnbernicDevice device = AnbernicDetector::detectDevice();
        AnbernicDeviceInfo deviceInfo = AnbernicDetector::getDeviceInfo(device);
        
        int screenWidth = 640;
        int screenHeight = 480;
        
        if (device != AnbernicDevice::Unknown) {
            std::cout << "Detected Anbernic device: " << deviceInfo.name << std::endl;
            std::cout << "Screen: " << deviceInfo.screenWidth << "x" 
                      << deviceInfo.screenHeight << std::endl;
            std::cout << "CPU: " << deviceInfo.cpu << std::endl;
            std::cout << "Analog Sticks: " << deviceInfo.analogStickCount << std::endl;
            
            screenWidth = deviceInfo.screenWidth;
            screenHeight = deviceInfo.screenHeight;
        } else {
            std::cout << "Running on generic platform" << std::endl;
        }

        SDL_Window* window = nullptr;
        SDL_GLContext glContext = nullptr;

        if (!InitializeSDL(&window, &glContext, "Valkyrie Engine - Samurai Babel", 
                          screenWidth, screenHeight)) {
            return 1;
        }

        SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
        if (!renderer) {
            SDL_GL_DeleteContext(glContext);
            SDL_DestroyWindow(window);
            SDL_Quit();
            return 1;
        }

        // Setup game controllers for Anbernic
        if (device != AnbernicDevice::Unknown) {
            std::cout << "Setting up gamepad support..." << std::endl;
            DetectConnectedGamepads();
        }

        const char* imagePath = "SamuraiBabel.png";
        SDL_Texture* imageTexture = LoadTexture(renderer, imagePath);
        if (!imageTexture) {
            std::cerr << "Warning: Could not load splash image" << std::endl;
        }

        Button button;
        button.x = 50;
        button.y = 150;
        button.width = 100;
        button.height = 30;
        button.color = {255, 0, 0};

        bool running = true;
        SDL_Event event;

        std::cout << "Entering main loop..." << std::endl;
        if (device != AnbernicDevice::Unknown) {
            std::cout << "Press START to exit, A/B buttons to interact" << std::endl;
        }

        while (running) {
            while (SDL_PollEvent(&event)) {
                if (event.type == SDL_QUIT) {
                    running = false;
                }

                // Handle gamepad events on Anbernic
                if (device != AnbernicDevice::Unknown) {
                    HandleGamepadEvents(event);
                    
                    // Anbernic button handling
                    if (event.type == SDL_CONTROLLERBUTTONDOWN) {
                        switch (event.cbutton.button) {
                            case SDL_CONTROLLER_BUTTON_A:
                                std::cout << "A button pressed" << std::endl;
                                break;
                            case SDL_CONTROLLER_BUTTON_B:
                                std::cout << "B button pressed" << std::endl;
                                break;
                            case SDL_CONTROLLER_BUTTON_START:
                                std::cout << "Start button pressed - Exiting..." << std::endl;
                                running = false;
                                break;
                            case SDL_CONTROLLER_BUTTON_BACK:
                                std::cout << "Select button pressed" << std::endl;
                                break;
                            default:
                                break;
                        }
                    }
                }

                // Handle keyboard input (for desktop/testing)
                if (event.type == SDL_KEYDOWN) {
                    switch (event.key.keysym.sym) {
                        case SDLK_ESCAPE:
                            std::cout << "ESC pressed - Exiting..." << std::endl;
                            running = false;
                            break;
                        case SDLK_RETURN:
                            std::cout << "Enter pressed" << std::endl;
                            break;
                        default:
                            break;
                    }
                }
            }

            SDL_RenderClear(renderer);

            if (imageTexture) {
                SDL_Rect imageRect = {0, 0, screenWidth, screenHeight};
                SDL_RenderCopy(renderer, imageTexture, nullptr, &imageRect);
            } else {
                // Fallback: draw colored background
                SDL_SetRenderDrawColor(renderer, 20, 30, 40, 255);
                SDL_RenderClear(renderer);
                
                // Draw a test rectangle
                SDL_Rect testRect = {
                    screenWidth / 4,
                    screenHeight / 4,
                    screenWidth / 2,
                    screenHeight / 2
                };
                SDL_SetRenderDrawColor(renderer, 100, 150, 200, 255);
                SDL_RenderFillRect(renderer, &testRect);
            }

            // Display device indicator for Anbernic
            if (device != AnbernicDevice::Unknown) {
                SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
                SDL_Rect indicator = {10, 10, 20, 20};
                SDL_RenderFillRect(renderer, &indicator);
            }

            SDL_RenderPresent(renderer);
            SDL_Delay(16); // ~60 FPS
        }

        // Cleanup
        if (imageTexture) {
            SDL_DestroyTexture(imageTexture);
        }
        SDL_DestroyRenderer(renderer);
        SDL_GL_DeleteContext(glContext);
        SDL_DestroyWindow(window);
        IMG_Quit();
        SDL_Quit();

        std::cout << "Valkyrie Engine shutdown complete" << std::endl;
        return 0;
    }
#endif