#ifndef GAMEPAD_H
#define GAMEPAD_H

#include <SDL2/SDL.h>
#include <vector>
#include <string>

// Structure to hold controller data
struct Gamepad {
    SDL_GameController* controller;
    SDL_JoystickID id;
    std::string name;
};

// Function declarations
bool InitializeGamepadSubsystem();
void DetectConnectedGamepads();
void HandleGamepadEvents(const SDL_Event& event);
extern std::vector<Gamepad> connectedGamepads;

#endif // GAMEPAD_H
