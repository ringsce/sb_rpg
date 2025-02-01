#include <SDL2/SDL.h>
#include "commands.h"
#include <iostream>

void handleInput(bool &running)
{
    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
        case SDL_QUIT:
            running = false;
            break;
        case SDL_KEYDOWN:
            switch (event.key.keysym.sym)
            {
            case SDLK_w:
                std::cout << "Moving Up" << std::endl;
                break;
            case SDLK_a:
                std::cout << "Moving Left" << std::endl;
                break;
            case SDLK_s:
                std::cout << "Moving Down" << std::endl;
                break;
            case SDLK_d:
                std::cout << "Moving Right" << std::endl;
                break;
            case SDLK_ESCAPE:
                running = false;
                break;
            }
            break;
        }
    }
}
