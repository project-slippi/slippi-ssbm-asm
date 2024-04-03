################################################################################
# Address: 0x8016d26c # VSModeThink while paused
################################################################################
.include "Common/Common.s"
.include "Online/Online.s"

lwz r4, OFST_R13_ODB_ADDR(r13)
lwz r3, ODB_PAUSE_COUNTER(r4)
addi r3, r3, 1
stw r3, ODB_PAUSE_COUNTER(r4)

# Replaced code line
addi r3, r31, 0