#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h> // SDL2_image for loading images
#include <Samurai_Babel.h>
#include <iostream>

#if defined(__APPLE__) && !defined(__ANDROID__)
// macOS/iOS includes
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#define GL_SILENCE_DEPRECATION
#elif defined(__ANDROID__) || defined(__linux__) || defined(_WIN32)
// Android/Linux/Windows includes (using GLES)
#include <GLES2/gl2.h>
#endif

// Function to initialize SDL and OpenGL/GLES context
bool InitializeSDL(SDL_Window **window, SDL_GLContext *glContext, const char *title, int width, int height) {
    // Initialize SDL2
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << "Error initializing SDL: " << SDL_GetError() << std::endl;
        return false;
    }

    // Initialize SDL2_image
    if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG)) {
        std::cerr << "Error initializing SDL_image: " << IMG_GetError() << std::endl;
        SDL_Quit();
        return false;
    }

// Set OpenGL attributes based on platform
#if defined(__APPLE__) && !defined(__ANDROID__)
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
#elif defined(__ANDROID__) || defined(__linux__) || defined(_WIN32)
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2); // GLES 2.0
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
#endif

    // Create an SDL window
    *window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height,
                               SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    if (!*window) {
        std::cerr << "Error creating window: " << SDL_GetError() << std::endl;
        return false;
    }

    // Create OpenGL/GLES context
    *glContext = SDL_GL_CreateContext(*window);
    if (!*glContext) {
        std::cerr << "Error creating GL context: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(*window);
        return false;
    }

    return true;
}

// Function to load a texture from a file
SDL_Texture* LoadTexture(SDL_Renderer *renderer, const char *filePath) {
    SDL_Surface *surface = IMG_Load(filePath);
    if (!surface) {
        std::cerr << "Error loading image: " << IMG_GetError() << std::endl;
        return nullptr;
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_FreeSurface(surface);

    if (!texture) {
        std::cerr << "Error creating texture: " << SDL_GetError() << std::endl;
    }

    return texture;
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    SDL_Window *window = nullptr;
    SDL_GLContext glContext = nullptr;

    if (!InitializeSDL(&window, &glContext, "SDL2 OpenGL/GLES Example with Image", 640, 480)) {
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        std::cerr << "Error creating renderer: " << SDL_GetError() << std::endl;
        SDL_GL_DeleteContext(glContext);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Load the SamuraiBabel.png image
    const char *imagePath = "SamuraiBabel.png"; // Ensure this file exists in the working directory
    SDL_Texture *imageTexture = LoadTexture(renderer, imagePath);
    if (!imageTexture) {
        SDL_DestroyRenderer(renderer);
        SDL_GL_DeleteContext(glContext);
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
        SDL_RenderCopy(renderer, imageTexture, nullptr, &imageRect);

        // Update the renderer
        SDL_RenderPresent(renderer);
    }

    // Cleanup
    SDL_DestroyTexture(imageTexture);
    SDL_DestroyRenderer(renderer);
    SDL_GL_DeleteContext(glContext);
    SDL_DestroyWindow(window);
    IMG_Quit();
    SDL_Quit();

    return 0;
}
