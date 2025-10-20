//
// Created by Pedro Dias Vicente on 20/10/2025.
//

// ============================================================================
// SDLWidget.cpp - Enhanced implementation
// ============================================================================

#include "SDLWidget.h"
#include <QWindow>
#include <QResizeEvent>
#include <QDebug>
#include <stdexcept>

SDLWidget::SDLWidget(QWidget *parent)
    : QWidget(parent)
{
    setAttribute(Qt::WA_PaintOnScreen);
    setAttribute(Qt::WA_OpaquePaintEvent);
    setAttribute(Qt::WA_NoSystemBackground);

    // Detect Anbernic device
    anbernicDevice = AnbernicDetector::detectDevice();
    deviceInfo = AnbernicDetector::getDeviceInfo(anbernicDevice);

    if (anbernicDevice != AnbernicDevice::Unknown) {
        qDebug() << "Detected Anbernic device:" << QString::fromStdString(deviceInfo.name);
        qDebug() << "Screen resolution:" << deviceInfo.screenWidth << "x" << deviceInfo.screenHeight;

        // Set widget size to match device screen
        setMinimumSize(deviceInfo.screenWidth, deviceInfo.screenHeight);
        setMaximumSize(deviceInfo.screenWidth, deviceInfo.screenHeight);
    } else {
        setMinimumSize(640, 480);
    }

    updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, &SDLWidget::updateSDL);
}

SDLWidget::~SDLWidget() {
    cleanupSDL();
}

void SDLWidget::showEvent(QShowEvent *event) {
    QWidget::showEvent(event);

    if (!initialized) {
        initializeSDL();
        // Higher framerate for Anbernic devices (they can handle it)
        updateTimer->start(anbernicDevice != AnbernicDevice::Unknown ? 16 : 16); // 60 FPS
    }
}

void SDLWidget::initializeSDL() {
    if (initialized) return;

    // Initialize SDL with gamecontroller support
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_JOYSTICK) < 0) {
        throw std::runtime_error(std::string("SDL initialization failed: ") + SDL_GetError());
    }

    // On Anbernic devices, we might want to use framebuffer directly
    if (anbernicDevice != AnbernicDevice::Unknown) {
        // Set SDL to use framebuffer on Linux-based handhelds
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengles2");
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1"); // Linear filtering

        // Enable gamecontroller events
        SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    }

    WId windowId = winId();

#ifdef Q_OS_WIN
    sdlWindow = SDL_CreateWindowFrom((void*)windowId);
#elif defined(Q_OS_LINUX)
    // For Anbernic (Linux ARM), use the window ID directly
    sdlWindow = SDL_CreateWindowFrom((void*)windowId);
#elif defined(Q_OS_MACOS)
    QWindow *window = windowHandle();
    if (window) {
        sdlWindow = SDL_CreateWindowFrom((void*)window->winId());
    }
#else
    sdlWindow = SDL_CreateWindowFrom((void*)windowId);
#endif

    if (!sdlWindow) {
        SDL_Quit();
        throw std::runtime_error(std::string("SDL window creation failed: ") + SDL_GetError());
    }

    // Create renderer optimized for the device
    Uint32 rendererFlags = SDL_RENDERER_ACCELERATED;

    if (anbernicDevice != AnbernicDevice::Unknown) {
        // Anbernic devices benefit from these settings
        rendererFlags |= SDL_RENDERER_PRESENTVSYNC;
    }

    renderer = SDL_CreateRenderer(sdlWindow, -1, rendererFlags);
    if (!renderer) {
        SDL_DestroyWindow(sdlWindow);
        SDL_Quit();
        throw std::runtime_error(std::string("SDL renderer creation failed: ") + SDL_GetError());
    }

    // Set logical rendering size for consistent scaling
    SDL_RenderSetLogicalSize(renderer, deviceInfo.screenWidth, deviceInfo.screenHeight);

    // Setup Anbernic controls
    if (anbernicDevice != AnbernicDevice::Unknown) {
        setupAnbernicControls();
    }

    initialized = true;
}

void SDLWidget::setupAnbernicControls() {
    // Open the first available game controller
    for (int i = 0; i < SDL_NumJoysticks(); ++i) {
        if (SDL_IsGameController(i)) {
            gameController = SDL_GameControllerOpen(i);
            if (gameController) {
                qDebug() << "Opened game controller:"
                         << SDL_GameControllerName(gameController);
                break;
            }
        }
    }

    if (!gameController) {
        qDebug() << "No game controller found. Button input may not work.";
    }
}

void SDLWidget::cleanupSDL() {
    if (updateTimer) {
        updateTimer->stop();
    }

    if (gameController) {
        SDL_GameControllerClose(gameController);
        gameController = nullptr;
    }

    if (renderer) {
        SDL_DestroyRenderer(renderer);
        renderer = nullptr;
    }

    if (sdlWindow) {
        SDL_DestroyWindow(sdlWindow);
        sdlWindow = nullptr;
    }

    SDL_Quit();
    initialized = false;
}

void SDLWidget::resizeEvent(QResizeEvent *event) {
    QWidget::resizeEvent(event);

    if (initialized && renderer) {
        // Maintain aspect ratio on resize
        SDL_RenderSetLogicalSize(renderer, deviceInfo.screenWidth, deviceInfo.screenHeight);
    }
}

void SDLWidget::updateSDL() {
    if (!initialized) return;

    handleAnbernicInput();
    renderSDL();
}

void SDLWidget::handleAnbernicInput() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
            case SDL_QUIT:
                qApp->quit();
                break;

            case SDL_CONTROLLERBUTTONDOWN:
                qDebug() << "Button pressed:" << event.cbutton.button;
                // Handle button presses
                switch (event.cbutton.button) {
                    case SDL_CONTROLLER_BUTTON_A:
                        qDebug() << "A button pressed";
                        break;
                    case SDL_CONTROLLER_BUTTON_B:
                        qDebug() << "B button pressed";
                        break;
                    case SDL_CONTROLLER_BUTTON_START:
                        qDebug() << "Start button pressed";
                        break;
                    case SDL_CONTROLLER_BUTTON_BACK:
                        qDebug() << "Select button pressed";
                        break;
                    default:
                        break;
                }
                break;

            case SDL_CONTROLLERAXISMOTION:
                // Handle analog stick movement
                if (deviceInfo.hasAnalogSticks) {
                    if (event.caxis.axis == SDL_CONTROLLER_AXIS_LEFTX ||
                        event.caxis.axis == SDL_CONTROLLER_AXIS_LEFTY) {
                        // Left stick movement
                        float value = event.caxis.value / 32767.0f;
                        if (abs(value) > 0.1f) { // Deadzone
                            qDebug() << "Left stick axis" << event.caxis.axis
                                     << "value:" << value;
                        }
                    }
                }
                break;

            case SDL_KEYDOWN:
                // Handle keyboard input (for testing on PC)
                qDebug() << "Key pressed:" << event.key.keysym.sym;
                break;

            default:
                break;
        }
    }
}

void SDLWidget::renderSDL() {
    // Clear screen
    SDL_SetRenderDrawColor(renderer, 20, 30, 40, 255);
    SDL_RenderClear(renderer);

    // Display device info
    if (anbernicDevice != AnbernicDevice::Unknown) {
        // Example: Draw a colored rectangle based on device
        SDL_Rect rect = {
            deviceInfo.screenWidth / 4,
            deviceInfo.screenHeight / 4,
            deviceInfo.screenWidth / 2,
            deviceInfo.screenHeight / 2
        };

        SDL_SetRenderDrawColor(renderer, 100, 200, 100, 255);
        SDL_RenderFillRect(renderer, &rect);

        // Draw device name (you'd need SDL_ttf for actual text)
        // For now, just draw some indicators
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        SDL_RenderDrawLine(renderer, 0, 0, deviceInfo.screenWidth, deviceInfo.screenHeight);
    } else {
        // Generic rendering for non-Anbernic devices
        SDL_Rect rect = {50, 50, 200, 150};
        SDL_SetRenderDrawColor(renderer, 255, 100, 100, 255);
        SDL_RenderFillRect(renderer, &rect);
    }

    SDL_RenderPresent(renderer);
}
