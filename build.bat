@echo off
echo Building netplay.json...
gecko build -c netplay.json -defsym "STG_EXIIndex=1"
echo.

echo Building playback.json...
gecko build -c playback.json -defsym "STG_EXIIndex=1"
echo.

echo Building console_core.json...
gecko build -c console_core.json -defsym "STG_EXIIndex=1" -o "Output/Console/g_core.bin"
echo.

echo Building console_core.json for Port A...
gecko build -c console_core.json -defsym "STG_EXIIndex=0" -o "Output/Console/g_core_porta.bin"
echo.

echo Building console_ControllerFixPlayerToggles.json...
gecko build -c console_ControllerFixPlayerToggles.json
echo.

echo Building console_UCF.json...
gecko build -c console_UCF.json
echo.

echo Building console_tournament.json...
gecko build -c console_tournament.json
echo.

echo Building console_PAL.json...
gecko build -c console_PAL.json
echo.

echo Building console_QOL.json...
gecko build -c console_QOL.json
echo.

echo Building console_frozen.json...
gecko build -c console_frozen.json
echo.

pause
