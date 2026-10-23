@echo off
echo Building netplay.json...
gecko build -c netplay.json -defsym "STG_EXIIndex=1" -cache
echo.

pause