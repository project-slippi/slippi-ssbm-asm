@echo off
echo Building console.json...
gecko build -c console.json
echo.

echo Building console_minimal.json...
gecko build -c console_minimal.json
echo.

echo Building netplay.json...
gecko build -c netplay.json
echo.

echo Building playback.json...
gecko build -c playback.json
echo.

pause
