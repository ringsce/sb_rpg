/*
The MIT License (MIT)

Copyright (c) 2013 The ioquake Group

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
#include <QApplication>
#include "mainwindow.h"

// Platform-specific includes
#if defined(_WIN32) && defined(_M_AMD64)
#include <windows.h>
#pragma message("Compiling for Windows 11 AMD64")
#elif defined(__linux__) && defined(__x86_64__)
#include <unistd.h>
#pragma message("Compiling for Linux AMD64")
#elif defined(__linux__) && defined(__aarch64__)
#include <unistd.h>
#pragma message("Compiling for Linux ARM64")
#elif defined(__APPLE__) && defined(__aarch64__)
#include <TargetConditionals.h>
#if TARGET_OS_MAC
#include <unistd.h>
#pragma message("Compiling for macOS ARM64")
#endif
#else
#error "Unsupported platform or architecture"
#endif

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    ioLaunch w;
// Platform-specific messages
#if defined(_WIN32) && defined(_M_AMD64)
    w.setWindowTitle("App - Windows 11 AMD64");
#elif defined(__linux__) && defined(__x86_64__)
    w.setWindowTitle("App - Linux AMD64");
#elif defined(__linux__) && defined(__aarch64__)
    w.setWindowTitle("App - Linux ARM64");
#elif defined(__APPLE__) && defined(__aarch64__)
    w.setWindowTitle("App - macOS ARM64");
#else
    w.setWindowTitle("App - Unsupported Platform");
#endif

    w.show();
    
    return a.exec();
}
