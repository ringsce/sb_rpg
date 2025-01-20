// main.cpp
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <iostream>
#include "game_utils.h"

// Platform-specific includes for cross-platform support
#if defined(__ANDROID__)
#include <GLES2/gl2.h>  // OpenGL ES for Android
#elif defined(__APPLE__) && !defined(__IOS__)
#include <OpenGL/gl.h>  // OpenGL for macOS
#include <OpenGL/glu.h>
#define GL_SILENCE_DEPRECATION
#elif defined(__IOS__)
#include <OpenGLES/ES2/gl.h>  // OpenGL ES for iOS
#elif defined(__linux__)
#include <GLES2/gl2.h>  // OpenGL ES for Linux ARM64
#elif defined(_WIN32)
#include <GLES2/gl2.h>  // OpenGL ES for Windows ARM64
#endif

struct Button {
    int x, y;
    int width, height;
    SDL_Color color;
};

bool InitializeSDL(SDL_Window** window, SDL_GLContext* glContext, const char* title, int width, int height);
void DrawCredits(SDL_Renderer* renderer, SDL_Texture* fontTexture, SDL_Rect buttonRect);

bool InitializeSDL(SDL_Window** window, SDL_GLContext* glContext, const char* title, int width, int height) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
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

/* to be tested doubled
 * void DrawCredits(SDL_Renderer* renderer, SDL_Texture* fontTexture, SDL_Rect buttonRect) {
    SDL_RenderCopy(renderer, fontTexture, nullptr, &buttonRect);
}*/

int main(int argc, char* argv[]) {
    SDL_Window* window = nullptr;
    SDL_GLContext glContext = nullptr;

    if (!InitializeSDL(&window, &glContext, "SDL2 Game Example", 640, 480)) {
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        SDL_GL_DeleteContext(glContext);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    const char* imagePath = "SamuraiBabel.png";
    SDL_Texture* imageTexture = LoadTexture(renderer, imagePath);
    if (!imageTexture) {
        SDL_DestroyRenderer(renderer);
        SDL_GL_DeleteContext(glContext);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Load font texture (replace with your own font)
    /*const char* fontPath = "font.png";
    SDL_Texture* fontTexture = LoadTexture(renderer, fontPath);
    if (!fontTexture) {
        return 1;
    }to be fixed*/

    Button button;
    button.x = 50;
    button.y = 150;
    button.width = 100;
    button.height = 30;
    button.color = {255, 0, 0};

    //SDL_Rect buttonRect = {100, 200, 150, 30};
    //DrawCredits(renderer, fontTexture, buttonRect);
    //SDL_RenderPresent(renderer);

    SDL_Delay(16);

    bool running = true;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
        }

        SDL_RenderClear(renderer);

        SDL_Rect imageRect = {0, 0, 640, 480};
        SDL_RenderCopy(renderer, imageTexture, nullptr, &imageRect);

        //SDL_RenderCopy(renderer, fontTexture, nullptr, &buttonRect);
        SDL_RenderPresent(renderer);

        SDL_Delay(16);
    }

    SDL_DestroyTexture(imageTexture);
    //SDL_DestroyTexture(fontTexture);
    SDL_DestroyRenderer(renderer);
    SDL_GL_DeleteContext(glContext);
    SDL_DestroyWindow(window);
    IMG_Quit();
    SDL_Quit();

    return 0;
}
