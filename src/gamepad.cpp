#include "gamepad.h"
#include <iostream>
#include <algorithm>

// Global vector to store connected controllers
std::vector<Gamepad> connectedGamepads;

bool InitializeGamepadSubsystem() {
    if (SDL_Init(SDL_INIT_GAMECONTROLLER) < 0) {
        std::cerr << "Failed to initialize SDL GameController subsystem: " << SDL_GetError() << std::endl;
        return false;
    }
    return true;
}

void DetectConnectedGamepads() {
    int joystickCount = SDL_NumJoysticks();

    for (int i = 0; i < joystickCount; ++i) {
        if (SDL_IsGameController(i)) {
            SDL_GameController* controller = SDL_GameControllerOpen(i);
            if (controller) {
                SDL_Joystick* joystick = SDL_GameControllerGetJoystick(controller);
                SDL_JoystickID id = SDL_JoystickInstanceID(joystick);
                const char* name = SDL_GameControllerName(controller);
                connectedGamepads.push_back({controller, id, name ? name : "Unknown Controller"});
                std::cout << "Connected: " << name << " (ID: " << id << ")" << std::endl;
            } else {
                std::cerr << "Failed to open game controller " << i << ": " << SDL_GetError() << std::endl;
            }
        }
    }
}

void HandleGamepadEvents(const SDL_Event& event) {
    switch (event.type) {
    case SDL_CONTROLLERDEVICEADDED: {
        int index = event.cdevice.which;
        if (SDL_IsGameController(index)) {
            SDL_GameController* controller = SDL_GameControllerOpen(index);
            if (controller) {
                SDL_Joystick* joystick = SDL_GameControllerGetJoystick(controller);
                SDL_JoystickID id = SDL_JoystickInstanceID(joystick);
                const char* name = SDL_GameControllerName(controller);
                connectedGamepads.push_back({controller, id, name ? name : "Unknown Controller"});
                std::cout << "Controller added: " << name << " (ID: " << id << ")" << std::endl;
            }
        }
        break;
    }
    case SDL_CONTROLLERDEVICEREMOVED: {
        SDL_JoystickID id = event.cdevice.which;
        auto it = std::remove_if(connectedGamepads.begin(), connectedGamepads.end(),
                                 [id](const Gamepad& g) { return g.id == id; });
        if (it != connectedGamepads.end()) {
            std::cout << "Controller removed: " << it->name << " (ID: " << it->id << ")" << std::endl;
            SDL_GameControllerClose(it->controller);
            connectedGamepads.erase(it);
        }
        break;
    }
    case SDL_CONTROLLERAXISMOTION: {
        SDL_JoystickID id = event.caxis.which;
        std::cout << "Controller ID: " << id
                  << ", Axis: " << event.caxis.axis
                  << ", Value: " << event.caxis.value << std::endl;
        break;
    }
    case SDL_CONTROLLERBUTTONDOWN:
    case SDL_CONTROLLERBUTTONUP: {
        SDL_JoystickID id = event.cbutton.which;
        std::cout << "Controller ID: " << id
                  << ", Button: " << (int)event.cbutton.button
                  << ", State: " << (event.cbutton.state == SDL_PRESSED ? "Pressed" : "Released") << std::endl;
        break;
    }
    }
}
