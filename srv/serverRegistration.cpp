#include <iostream>
#include <string>
#include <curl/curl.h>

// Helper function to perform HTTP POST request
std::string performPostRequest(const std::string &url, const std::string &postFields) {
    CURL *curl = curl_easy_init();
    std::string response;

    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postFields.c_str());

        // Write callback to capture the response
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, [](char *data, size_t size, size_t nmemb, std::string *writerData) -> size_t {
            if (writerData) {
                writerData->append(data, size * nmemb);
                return size * nmemb;
            }
            return 0;
        });
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            std::cerr << "CURL error: " << curl_easy_strerror(res) << std::endl;
        }
        curl_easy_cleanup(curl);
    }
    return response;
}

// Function to register a client
bool registerClient(const std::string &username, const std::string &password) {
    std::string url = "https://ringscejs.gleentech.com/register";
    std::string postFields = "username=" + username + "&password=" + password;

    std::string response = performPostRequest(url, postFields);
    if (response == "OK") {
        std::cout << "Registration successful!" << std::endl;
        return true;
    } else {
        std::cerr << "Registration failed: " << response << std::endl;
        return false;
    }
}

// Function to validate a client
bool validateClient(const std::string &username, const std::string &password) {
    std::string url = "https://ringscejs.gleentech.com/validate";
    std::string postFields = "username=" + username + "&password=" + password;

    std::string response = performPostRequest(url, postFields);
    if (response == "OK") {
        std::cout << "Login successful!" << std::endl;
        return true;
    } else {
        std::cerr << "Login failed: " << response << std::endl;
        return false;
    }
}