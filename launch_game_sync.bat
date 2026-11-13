@echo off
cd /d "%~dp0"
start "Rojo Server" cmd /k "rojo.exe serve"
start "" "HorrorGame.rbxl"
exit
