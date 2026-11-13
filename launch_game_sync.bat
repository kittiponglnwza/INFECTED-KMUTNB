@echo off
chcp 65001 >nul
title HorrorGame - Real-Time Sync Launcher
cd /d "%~dp0"

echo =======================================================
echo   🚀 กำลังเปิดแมพ HorrorGame พร้อมระบบ Real-Time Sync
echo =======================================================
echo.

:: ตรวจสอบว่า rojo.exe กำลังรันอยู่แล้วหรือไม่
tasklist /FI "IMAGENAME eq rojo.exe" 2>NUL | find /I /N "rojo.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo [✓] Rojo Live Server กำลังทำงานอยู่แล้ว
) else (
    echo [*] กำลังเริ่ม Rojo Live Sync Server (Port 34872)...
    start "Rojo Live Server" cmd /c "title Rojo Live Server && chcp 65001 >nul && echo Rojo Server กำลังทำงาน... ห้ามปิดหน้าต่างนี้เพื่อความ Real-time && echo. && rojo.exe serve"
    timeout /t 2 /nobreak >nul
)

echo [*] กำลังเปิด HorrorGame.rbxl ใน Roblox Studio...
start "" "HorrorGame.rbxl"

echo.
echo =======================================================
echo   ✅ เปิดเกมและเริ่มเซิร์ฟเวอร์ Sync เรียบร้อย!
echo   (เมื่อ Studio เปิดขึ้นมา หากใช้ปลั๊กอิน Rojo ให้กด Connect)
echo =======================================================
echo.
timeout /t 3 >nul
