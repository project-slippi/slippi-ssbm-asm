################################################################################
# Address: 0x801d2d38
################################################################################
# Will change the text on the jumbotron to "Frozen"
################################################################################

.include "Common/Common.s"

.set REG_DATA, 20
.set REG_COUNT, 21
.set REG_DEST, 22

b CODE_START

# Hardcode data as stage files aren't currently loaded through the slippi file loader
DATA_BLRL:
blrl

.set FROZEN_SIS, 0
.long 0x100CC0C0
.long 0xFF16400F
.long 0x40354032
.long 0x403D4028
.long 0x40311703
.long 0x110D0000

CODE_START:
  backup

  computeBranchTargetAddress r3, INJ_FREEZE_STADIUM
  lbz r3, 0x8(r3) # Load whether stadium is frozen
  cmpwi r3, 0
  beq EXIT

  bl DATA_BLRL
  mflr REG_DATA

  load r5, 0x804d1124 # SIS Data
  li r4, 8 # String Idx > 'Normal''

  lwz r5, 4(r5) # SISData[1]
  rlwinm	r0, r4, 2, 0, 29 # offset of string
  lwzx	REG_DEST, r5, r0 # 'Normal'
  
  li REG_COUNT, 0
  OVERWRITE_STR_LOOP:
  mulli r0, REG_COUNT, 4
  lwzx r3, REG_DATA, r0
  stwx r3, REG_DEST, r0
  
  OVERWRITE_STR_CHECK:
    addi REG_COUNT, REG_COUNT, 1
    cmpwi REG_COUNT, 6
    blt OVERWRITE_STR_LOOP

EXIT:
  restore
  mr	r3, r30
