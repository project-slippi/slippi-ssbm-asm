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

set list=console_UCF.json
set list=%list%;console_UCF_stealth.json
set list=%list%;console_ControllerFixPlayerToggles.json
set list=%list%;console_mods_stealth.json
set list=%list%;console_mods_tournament.json
set list=%list%;console_mods_friendlies.json
set list=%list%;console_PAL.json
set list=%list%;console_frozen.json
set list=%list%;console_lag_pd.json
set list=%list%;console_lag_pdvb.json
set list=%list%;console_widescreen.json

for %%a in (%list%) do (
  echo Building %%a...
  gecko build -c %%a
  echo.
)

pause
