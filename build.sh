#!/bin/bash
source ./build-netplay.sh

source ./build-playback.sh

echo Building console_core.json...
gecko build -c console_core.json -defsym "STG_EXIIndex=1" -o "Output/Console/g_core.bin"
echo ""

echo Building console_core.json for Port A...
gecko build -c console_core.json -defsym "STG_EXIIndex=0" -o "Output/Console/g_core_porta.bin"
echo ""

list=(
    "console_UCF.json"
    "console_UCF_stealth.json"
    "console_ControllerFixPlayerToggles.json"
    "console_mods_stealth.json"
    "console_mods_tournament.json"
    "console_mods_friendlies.json"
    "console_PAL.json"
    "console_frozen.json"
    "console_lag_pd.json"
    "console_lag_pdvb.json"
)

for file in "${list[@]}"
do
  echo "Building $file..."
  gecko build -c "$file"
  echo ""
done

