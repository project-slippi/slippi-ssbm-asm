@echo off
echo Building netplay.json...
gecko build -c netplay.json
echo.

echo Building playback.json...
gecko build -c playback.json
echo.

echo Building console_core.json...
gecko build -c console_core.json
echo.

echo Building console_ControllerFixPlayerToggles.json...
gecko build -c console_ControllerFixPlayerToggles.json
echo.

echo Building console_UCF.json...
gecko build -c console_UCF.json
echo.

echo Building console_NeutralSpawns.json...
gecko build -c console_NeutralSpawns.json
echo.

echo Building console_PAL.json...
gecko build -c console_PAL.json
echo.

echo Building console_QOL.json...
gecko build -c console_QOL.json
echo.

pause
