@echo off
echo Building console_core.json...
gecko build -c console_core.json -defsym "STG_EXIIndex=1" -cache
echo.

pause