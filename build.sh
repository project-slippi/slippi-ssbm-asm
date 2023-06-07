#!/bin/bash
source ./build-netplay.sh

source ./build-playback.sh

echo Building console_core.json for Port A...
gecko build -c console_core.json -defsym "STG_EXIIndex=0" -o "Output/Console/g_core_porta.bin"
echo ""

echo Building console_core.json...
gecko build -c console_core.json -defsym "STG_EXIIndex=1" -o "Output/Console/g_core.bin"
echo ""

list=(
    "console_UCF.json"
    "console_UCF_stealth.json"
    "console_UCF_084.json"
    "console_UCF_084_stealth.json"
    "console_mods_stealth.json"
    "console_mods_tournament.json"
    "console_mods_friendlies.json"
    "console_PAL.json"
    "console_stages_stadium.json"
    "console_stages_all.json"
    "console_gameplay_lgl.json"
    "console_gameplay_wobbling.json"
    "console_gameplay_both.json"
    "console_lag_pd.json"
    "console_lag_pdhalfvb.json"
    "console_screen_wide.json"
    "console_screen_wide_shutters.json"
    "console_safety.json"
)

for file in "${list[@]}"
do
  echo "Building $file..."
  gecko build -c "$file"
  echo ""
done

