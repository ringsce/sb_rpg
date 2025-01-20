#include <stdio.h>
#include <stdbool.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>

// Function to initialize SDL and create a window
bool InitializeSDL(SDL_Window **window, SDL_Renderer **renderer, const char *title, int width, int height) {
    // Initialize SDL2
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "Error initializing SDL: %s\n", SDL_GetError());
        return false;
    }

    // Initialize SDL2_image
    if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG)) {
        fprintf(stderr, "Error initializing SDL_image: %s\n", IMG_GetError());
        SDL_Quit();
        return false;
    }

    // Create an SDL window
    *window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, SDL_WINDOW_SHOWN);
    if (!*window) {
        fprintf(stderr, "Error creating window: %s\n", SDL_GetError());
        return false;
    }

    // Create an SDL renderer
    *renderer = SDL_CreateRenderer(*window, -1, SDL_RENDERER_ACCELERATED);
    if (!*renderer) {
        fprintf(stderr, "Error creating renderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(*window);
        return false;
    }

    return true;
}

// Function to load a texture from a file
SDL_Texture* LoadTexture(SDL_Renderer *renderer, const char *filePath) {
    SDL_Surface *surface = IMG_Load(filePath);
    if (!surface) {
        fprintf(stderr, "Error loading image: %s\n", IMG_GetError());
        return NULL;
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_FreeSurface(surface);

    if (!texture) {
        fprintf(stderr, "Error creating texture: %s\n", SDL_GetError());
    }

    return texture;
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    SDL_Window *window = NULL;
    SDL_Renderer *renderer = NULL;

    if (!InitializeSDL(&window, &renderer, "SDL2 AROS Example", 640, 480)) {
        SDL_Quit();
        return 1;
    }

    // Load the image
    const char *imagePath = "SamuraiBabel.png"; // Ensure this file exists in the working directory
    SDL_Texture *imageTexture = LoadTexture(renderer, imagePath);
    if (!imageTexture) {
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Main loop
    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
        }

        // Clear the screen
        SDL_RenderClear(renderer);

        // Render the image
        SDL_Rect imageRect = {0, 0, 640, 480}; // Adjust as needed for the image
        SDL_RenderCopy(renderer, imageTexture, NULL, &imageRect);

        // Update the renderer
        SDL_RenderPresent(renderer);
    }

    // Cleanup
    SDL_DestroyTexture(imageTexture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    IMG_Quit();
    SDL_Quit();

    return 0;
}

