// src/MainWindow.h - Qt6 Main Window with SDL Widget

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QMenuBar>
#include <QMenu>
#include <QAction>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QStatusBar>
#include "SDLWidget.h"

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onAbout();
    void onQuit();
    void onFullscreen();
    void onDeviceInfo();

private:
    void createMenus();
    void createStatusBar();
    void setupUI();

    SDLWidget *sdlWidget;
    QLabel *statusLabel;
    QAction *fullscreenAction;
    bool isFullscreen = false;
};

#endif // MAINWINDOW_H