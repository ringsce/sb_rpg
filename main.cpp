#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include "src/gamepad.h"
#include <iostream>

bool InitializeSDL(SDL_Window** window, SDL_GLContext* glContext, const char* title, int width, int height);
SDL_Texture* LoadTexture(SDL_Renderer* renderer, const char* filePath);

bool InitializeSDL(SDL_Window** window, SDL_GLContext* glContext, const char* title, int width, int height) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) != 0) {
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

SDL_Texture* LoadTexture(SDL_Renderer* renderer, const char* filePath) {
    SDL_Surface* surface = IMG_Load(filePath);
    if (!surface) {
        std::cerr << "Error loading image: " << IMG_GetError() << std::endl;
        return nullptr;
    }

    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_FreeSurface(surface);

    if (!texture) {
        std::cerr << "Error creating texture: " << SDL_GetError() << std::endl;
    }

    return texture;
}

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

    if (!InitializeGamepadSubsystem()) {
        return 1;
    }

    DetectConnectedGamepads();

    bool running = true;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
            HandleGamepadEvents(event);
        }

        SDL_RenderClear(renderer);
        SDL_Rect imageRect = {0, 0, 640, 480};
        SDL_RenderCopy(renderer, imageTexture, nullptr, &imageRect);
        SDL_RenderPresent(renderer);
        SDL_Delay(16); // 60 FPS
    }

    for (auto& gamepad : connectedGamepads) {
        SDL_GameControllerClose(gamepad.controller);
    }

    SDL_DestroyTexture(imageTexture);
    SDL_DestroyRenderer(renderer);
    SDL_GL_DeleteContext(glContext);
    SDL_DestroyWindow(window);
    IMG_Quit();
    SDL_Quit();

    return 0;
}
