//
// Created by Pedro Dias Vicente on 18/10/2025.
//

#ifndef SERVERREGISTRATION_H
#define SERVERREGISTRATION_H

#include <string>

// Helper function to perform HTTP POST request
std::string performPostRequest(const std::string &url, const std::string &postFields);

// Function to register a client
bool registerClient(const std::string &username, const std::string &password);

// Function to validate a client
bool validateClient(const std::string &username, const std::string &password);

#endif // SERVERREGISTRATION_H