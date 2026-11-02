################################################################################
# Address: 0x801cd37c # Start of Stage_Castle_stageInit, runs once when the stage loads
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"

# The wind on this stage keeps two values in static data, which outlive a game. One of them decides
# whether the wind uses up an extra random number every 300 frames, so players that had played on
# this stage differently before would end up with different seeds and desync. This sets them to the
# values they have when the game boots.
.set WIND_STEP_ADDR, 0x804d45e0
.set WIND_MODE_ADDR, 0x804d45e4
.set WIND_STEP_INITIAL, 0x3c8efa35 # 0.01745
.set WIND_MODE_INITIAL, 1

load r3, WIND_STEP_INITIAL
load r4, WIND_STEP_ADDR
stw r3, 0(r4)
li r3, WIND_MODE_INITIAL
load r4, WIND_MODE_ADDR
stb r3, 0(r4)

EXIT:
mflr r0
