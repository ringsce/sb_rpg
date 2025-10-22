//
// Created by Pedro Dias Vicente on 20/10/2025.
//
// src/MainWindow.cpp - Qt6 Main Window with SDL Widget

#include "MainWindow.h"
#include "ANBERNIC_CONFIG.h"
#include <QMessageBox>
#include <QKeySequence>
#include <QDebug>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    setWindowTitle("Valkyrie Engine - Samurai Babel MMO RPG");

    // Detect Anbernic device
    AnbernicDevice device = AnbernicDetector::detectDevice();
    AnbernicDeviceInfo deviceInfo = AnbernicDetector::getDeviceInfo(device);

    if (device != AnbernicDevice::Unknown) {
        resize(deviceInfo.screenWidth, deviceInfo.screenHeight);
        setMaximumSize(deviceInfo.screenWidth, deviceInfo.screenHeight);
        setMinimumSize(deviceInfo.screenWidth, deviceInfo.screenHeight);
    } else {
        resize(800, 600);
    }

    setupUI();
    createMenus();
    createStatusBar();

    // Show device info in status bar
    if (device != AnbernicDevice::Unknown) {
        statusLabel->setText(QString("Device: %1 | Resolution: %2x%3")
            .arg(QString::fromStdString(deviceInfo.name))
            .arg(deviceInfo.screenWidth)
            .arg(deviceInfo.screenHeight));
    } else {
        statusLabel->setText("Valkyrie Engine - Ready");
    }
}

MainWindow::~MainWindow() {
}

void MainWindow::setupUI() {
    // Create central widget
    QWidget *centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);

    // Create main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(centralWidget);
    mainLayout->setContentsMargins(0, 0, 0, 0);
    mainLayout->setSpacing(0);

    // Create SDL widget for game rendering
    sdlWidget = new SDLWidget(this);
    mainLayout->addWidget(sdlWidget, 1);

    // Only show control buttons on desktop (not on Anbernic)
    if (!sdlWidget->isRunningOnAnbernic()) {
        QHBoxLayout *buttonLayout = new QHBoxLayout();

        QPushButton *fullscreenBtn = new QPushButton("Fullscreen", this);
        QPushButton *infoBtn = new QPushButton("Device Info", this);

        connect(fullscreenBtn, &QPushButton::clicked, this, &MainWindow::onFullscreen);
        connect(infoBtn, &QPushButton::clicked, this, &MainWindow::onDeviceInfo);

        buttonLayout->addWidget(fullscreenBtn);
        buttonLayout->addWidget(infoBtn);
        buttonLayout->addStretch();

        mainLayout->addLayout(buttonLayout);
    }
}

void MainWindow::createMenus() {
    // Only create menus on desktop
    if (!sdlWidget->isRunningOnAnbernic()) {
        QMenu *fileMenu = menuBar()->addMenu("&File");

        fullscreenAction = new QAction("&Fullscreen", this);
        fullscreenAction->setShortcut(QKeySequence(Qt::Key_F11));
        connect(fullscreenAction, &QAction::triggered, this, &MainWindow::onFullscreen);
        fileMenu->addAction(fullscreenAction);

        fileMenu->addSeparator();

        QAction *quitAction = new QAction("&Quit", this);
        quitAction->setShortcut(QKeySequence::Quit);
        connect(quitAction, &QAction::triggered, this, &MainWindow::onQuit);
        fileMenu->addAction(quitAction);

        QMenu *helpMenu = menuBar()->addMenu("&Help");

        QAction *deviceInfoAction = new QAction("&Device Info", this);
        connect(deviceInfoAction, &QAction::triggered, this, &MainWindow::onDeviceInfo);
        helpMenu->addAction(deviceInfoAction);

        QAction *aboutAction = new QAction("&About", this);
        connect(aboutAction, &QAction::triggered, this, &MainWindow::onAbout);
        helpMenu->addAction(aboutAction);
    }
}

void MainWindow::createStatusBar() {
    statusLabel = new QLabel(this);
    statusBar()->addWidget(statusLabel, 1);
}

void MainWindow::onAbout() {
    QMessageBox::about(this, "About Valkyrie Engine",
        "Valkyrie Engine\n"
        "Samurai Babel MMO RPG\n\n"
        "A cross-platform game engine with support for:\n"
        "- macOS (Apple Silicon & Intel)\n"
        "- Linux Desktop\n"
        "- Anbernic Handheld Consoles\n\n"
        "Built with SDL2 and Qt6");
}

void MainWindow::onQuit() {
    close();
}

void MainWindow::onFullscreen() {
    if (isFullscreen) {
        showNormal();
        if (fullscreenAction) {
            fullscreenAction->setText("&Fullscreen");
        }
        isFullscreen = false;
    } else {
        showFullScreen();
        if (fullscreenAction) {
            fullscreenAction->setText("Exit &Fullscreen");
        }
        isFullscreen = true;
    }
}

void MainWindow::onDeviceInfo() {
    AnbernicDevice device = sdlWidget->getAnbernicDevice();
    AnbernicDeviceInfo info = AnbernicDetector::getDeviceInfo(device);

    QString message;
    if (device != AnbernicDevice::Unknown) {
        message = QString(
            "Device: %1\n"
            "CPU: %2\n"
            "Resolution: %3x%4\n"
            "WiFi: %5\n"
            "Analog Sticks: %6\n"
            "Touch Screen: %7"
        ).arg(QString::fromStdString(info.name))
         .arg(QString::fromStdString(info.cpu))
         .arg(info.screenWidth)
         .arg(info.screenHeight)
         .arg(info.hasWifi ? "Yes" : "No")
         .arg(info.analogStickCount)
         .arg(info.touchScreen ? "Yes" : "No");
    } else {
        message = "Running on desktop/generic platform\n"
                  "No Anbernic device detected";
    }

    QMessageBox::information(this, "Device Information", message);
}