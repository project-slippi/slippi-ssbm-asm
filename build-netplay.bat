@echo off
echo Building netplay.json...
gecko build -c netplay.json -defsym "STG_EXIIndex=1"
echo.

copy Output\Netplay\GALE01r2.ini "..\Ishiiruka\Binary\x64\Sys\GameSettings\GALE01r2.ini"
copy Output\Netplay\GALE01r2.ini "..\Ishiiruka\Binary\x64 - p2\Sys\GameSettings\GALE01r2.ini"

pause
