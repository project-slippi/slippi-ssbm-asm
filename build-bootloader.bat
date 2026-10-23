@echo off
echo Building bootloader.json...
gecko build -c bootloader.json -defsym "STG_EXIIndex=1" -cache
echo.

pause
