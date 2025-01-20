#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <iostream>
#include "game_utils.h"  // Include the header file for LoadTexture and other utility functions

// Function to draw the credits
void DrawCredits(SDL_Renderer* renderer, SDL_Texture* fontTexture, SDL_Rect buttonRect) {
    // Render the button for credits (this could be extended to display a more detailed credits screen)
    SDL_RenderCopy(renderer, fontTexture, nullptr, &buttonRect);
}

// You can add other credits-specific functions here, for example, handling scrolling credits or additional UI elements
void DisplayCredits(SDL_Renderer* renderer) {
    // Example: drawing a simple credits screen (you can expand this with more details)
    const char* fontPath = "font.png";
    SDL_Texture* fontTexture = LoadTexture(renderer, fontPath);

    if (!fontTexture) {
        std::cerr << "Error loading font texture for credits" << std::endl;
        return;
    }

    // Set up button or text for credits
    SDL_Rect buttonRect = {100, 200, 300, 50};  // Sample position and size for a "credits" button

    // Clear the screen and draw the credits
    SDL_RenderClear(renderer);
    DrawCredits(renderer, fontTexture, buttonRect);
    SDL_RenderPresent(renderer);
}
