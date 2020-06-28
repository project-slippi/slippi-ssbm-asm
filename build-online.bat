@echo off
echo Building online.json...
gecko build -c online.json -defsym "STG_EXIIndex=1" -o "Output/Online/online.txt"
echo.

pause
