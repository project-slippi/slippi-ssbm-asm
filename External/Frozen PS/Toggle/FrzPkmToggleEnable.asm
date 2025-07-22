################################################################################
# Address: INJ_FREEZE_STADIUM
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"

# This code just makes it easier for the playback engine to check if stadium is currently frozen on
# console as this is the location where it's stored both online and now on console as well

# affects-gameplay is on such that if we regenerate the replay, it should maintain the frozen value
# in the replay. This code is not actually required for PS to actually be frozen, just for the
# playback engine to know if it is frozen or not when writing the replay

b CODE_START
STATIC_MEMORY_TABLE_BLRL:
blrl
.byte 0x1 # Indicate frozen toggle is enabled
.align 2

CODE_START:
# Replaced code line
branchl r12, 0x8018841c # MenuController_TrainingModeCheck

EXIT: