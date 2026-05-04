@echo off
REM Fix QR Codes Script for Windows
REM This script updates all tables with proper QR code data

echo.
echo 🚀 Fixing QR Codes for All Tables...
echo.

REM Check if .env file exists
if not exist .env (
    echo ❌ Error: .env file not found!
    echo Please create a .env file with MONGODB_URI and WEB_APP_URL
    pause
    exit /b 1
)

REM Run the fix script
node src/utils/fix-table-qr-codes.js

echo.
echo ✅ Done! You can now download QR codes from the admin panel.
echo.
pause
