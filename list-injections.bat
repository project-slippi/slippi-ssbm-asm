@echo off

set list=netplay.json
set list=%list%;console_core.json
set list=%list%;console_UCF.json
set list=%list%;console_UCF_stealth.json
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
  echo Listing %%a...
  gecko list -i %%a -o Output/InjectionLists/list_%%a
  echo.
)

pause
