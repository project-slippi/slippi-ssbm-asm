################################################################################
# Address: 0x8025a530
# SSS_CursorThink 
################################################################################

.include "Common/Common.s"
.include "./SSSToggles.s"

.set REG_IDX, 30
.set REG_FROZEN, 22
.set REG_DATA, 21
.set REG_JOBJ, 20

.set CLR_HOVER, 0x8052D5FF
.set CLR_DEFAULT, 0x99B3B3FF

b CODE_START

DATA_BLRL:
blrl
.set FROZEN_TOGGLE, 0
.byte 0
.align 2

CODE_START:
  backup
# load frozen var
  # load REG_DATA, SSS_CustomData
  # lbz REG_FROZEN, 0(REG_DATA)
  bl DATA_BLRL
  mflr REG_DATA

# check if we pressed z
  load r3, HSD_PadMaster
  lwz r4, 0x8(r3) # instant buttons
  rlwinm. r0, r4, 0, 27, 27 # z button is bit 4
  beq PAD_CHECK_END
  
# weve pressed z, so toggle stadium
  lbz r4, 0(REG_DATA)
  xori r4, r4, 1
  stb r4, 0(REG_DATA)
  stb r4, FSToggle(rtoc)
  PAD_CHECK_END:

# get our jobj
  loadwz r3, GOBJ_Current
  lwz REG_JOBJ, 0x28(r3)
  
# check if the icon hovered is stadium
  cmpwi REG_IDX, ID_GRPS
  bne ON_UNHOVERED

ON_HOVER:
# on hover, turn it purple
  load r4, CLR_HOVER
  lwz r3, 0x18(REG_JOBJ) # dobj
  lwz r3, 0x8(r3) # mobj
  lwz r3, 0xC(r3) # material
  stw r4, 4(r3) # ambient color

  b EXIT

ON_UNHOVERED:
# restore default color when hovered over another icon
  load r4, CLR_DEFAULT
  lwz r3, 0x18(REG_JOBJ) # dobj
  lwz r3, 0x8(r3) # mobj
  lwz r3, 0xC(r3) # material
  stw r4, 4(r3) # ambient color

EXIT:
  restore
  stb	r30, -0x49F2(r13)