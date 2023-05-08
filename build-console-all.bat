@echo off
echo Building console_core.json for Port A...
gecko build -c console_core.json -defsym "STG_EXIIndex=0" -o "Output/Console/g_core_porta.bin" -batched
echo.

echo Building console_core.json...
gecko build -c console_core.json -defsym "STG_EXIIndex=1" -o "Output/Console/g_core.bin" -batched
echo.

set list=console_UCF.json
set list=%list%;console_UCF_stealth.json
set list=%list%;console_UCF_084.json
set list=%list%;console_UCF_084_stealth.json
set list=%list%;console_mods_stealth.json
set list=%list%;console_mods_tournament.json
set list=%list%;console_mods_friendlies.json
set list=%list%;console_PAL.json
set list=%list%;console_stages_stadium.json
set list=%list%;console_stages_all.json
set list=%list%;console_gameplay_lgl.json
set list=%list%;console_gameplay_wobbling.json
set list=%list%;console_gameplay_both.json
set list=%list%;console_lag_pd.json
set list=%list%;console_lag_pdhalfvb.json
set list=%list%;console_screen_wide.json
set list=%list%;console_screen_wide_shutters.json
set list=%list%;console_safety.json
set list=%list%;console_crash_output.json

for %%a in (%list%) do (
  echo Building %%a...
  gecko build -c %%a
  echo.
)

pause
