@echo off
echo Building ai_inputs.json...
gecko build -c ai_inputs.json -defsym "STG_EXIIndex=1" -batched
echo.

pause