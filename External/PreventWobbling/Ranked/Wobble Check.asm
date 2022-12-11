################################################################################
# Address: 8008F090
# Tags: [affects-gameplay]
################################################################################
.include "External/PreventWobbling/PreventWobbling.s"
.include "Online/Online.s"
.include "Common/Common.s"

# TODO: This doesn't actually work. It would be enabled for all online games when playing but
# TODO: if you went to VS mode to play a local game, it wouldn't be enabled when playing but would
# TODO: be enabled when that replay was played. We will have to pass the scene and mode the game
# TODO: was played to the playback engine to properly decide when to enable this code in a replay

# Only run this code in ranked and playback
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
beq EXEC_CODE
cmpwi r3, SCENE_PLAYBACK_IN_GAME
beq EXEC_CODE
b WRAPPER_EXIT

EXEC_CODE:
Wobbling_Check

WRAPPER_EXIT:
#Original codeline
lwz	r0, 0x0010 (r27)