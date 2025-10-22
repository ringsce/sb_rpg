//
// Created by Pedro Dias Vicente on 20/10/2025.
//

// ============================================================================
// SDLWidget.h - Enhanced with Anbernic support
// ============================================================================

#ifndef SDLWIDGET_H
#define SDLWIDGET_H

#include <QWidget>
#include <QTimer>
#include <SDL.h>
#include "ANBERNIC_CONFIG.h"

class SDLWidget : public QWidget {
    Q_OBJECT

public:
    explicit SDLWidget(QWidget *parent = nullptr);
    ~SDLWidget() override;

    SDL_Renderer* getRenderer() { return renderer; }
    SDL_Window* getWindow() { return sdlWindow; }
    bool isRunningOnAnbernic() const { return anbernicDevice != AnbernicDevice::Unknown; }
    AnbernicDevice getAnbernicDevice() const { return anbernicDevice; }

protected:
    void showEvent(QShowEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;
    QPaintEngine* paintEngine() const override { return nullptr; }

private slots:
    void updateSDL();

private:
    void initializeSDL();
    void cleanupSDL();
    void renderSDL();
    void setupAnbernicControls();
    void handleAnbernicInput();

    SDL_Window *sdlWindow = nullptr;
    SDL_Renderer *renderer = nullptr;
    QTimer *updateTimer = nullptr;
    bool initialized = false;

    // Anbernic specific
    AnbernicDevice anbernicDevice = AnbernicDevice::Unknown;
    AnbernicDeviceInfo deviceInfo;
    SDL_GameController *gameController = nullptr;
};

#endif // SDLWIDGET_H
