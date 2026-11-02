################################################################################
# Address: 0x801d69b0 # Start of KongoLogBridge_Init, runs once when the stage loads
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"

# The log bridge keeps its physics in static data, which outlives a game. The game resets each log's
# angle here but not its velocity, and the first physics step applies that velocity right away. The
# side platforms rotate with the logs and players spawn on them, so players that had played on this
# stage differently before would start in different places and desync.
.set LOG_COUNT, 15
.set LOG_SIZE, 0x18
.set FIRST_LOG_VELOCITY, 0x803e188c + 0x10

load r4, FIRST_LOG_VELOCITY
li r5, 0 # 0.0
li r6, LOG_COUNT
mtctr r6
LOOP_START:
stw r5, 0(r4)
addi r4, r4, LOG_SIZE
bdnz LOOP_START

EXIT:
mflr r0
