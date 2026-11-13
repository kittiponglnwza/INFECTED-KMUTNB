@echo off
chcp 65001 >nul
title Rojo Live Server
cd /d "%~dp0"
echo ===================================================
echo   Starting Rojo Live Sync Server for Roblox Studio
echo ===================================================
echo.
echo 1. Open Roblox Studio with HorrorGame.rbxl
echo 2. Go to Plugins tab -> Click Rojo -> Click "Connect"
echo.
echo Server running on http://localhost:34872
echo.
rojo.exe serve
pause
