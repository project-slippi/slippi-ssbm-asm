################################################################################
# Address: 0x80302784
################################################################################
.include "../../Common/Common.s"

b CODE_START

DATA_BLRL:
blrl
.set DO_X_SCALE, 0
.float 114 # previously 34
.set DO_Y_SCALE, DO_X_SCALE + 4
.float 1000
.set DO_COLOR, DO_Y_SCALE + 4
.byte 0,0,0,255

################################################################################
# Function: InitRectangle
################################################################################
# Inputs:
# r3: isLeft # True if this is the left shutter, False if right
################################################################################
.set REG_DATA, 31
.set REG_DevelopText, 30
.set REG_X_POS, 29
.set REG_ID, 28

FN_InitShutter:
backup

  li REG_ID, 20
  li REG_X_POS, -25
  cmpwi r3, 0
  beq FN_InitShutter_SKIP_RIGHT
  li REG_ID, 21
  li REG_X_POS, 561
  FN_InitShutter_SKIP_RIGHT:

  bl DATA_BLRL
  mflr REG_DATA

#Create Rectangle
  li  r3,32
  branchl r12,HSD_MemAlloc
  mr  r8,r3
  mr  r3,REG_ID
  mr r4,REG_X_POS
  li  r5,-25
  li  r6,1
  li  r7,1
  branchl r12, 0x80302834 # DevelopText_CreateDataTable
  mr  REG_DevelopText,r3
#Activate Text
  lwz	r3, -0x4884 (r13)
  mr  r4,REG_DevelopText
  branchl r12, 0x80302810 # DevelopText_Activate
#Hide blinking cursor
  li  r3,0
  stb r3,0x26(REG_DevelopText)
#Change BG Color
  mr  r3,REG_DevelopText
  addi  r4,REG_DATA,DO_COLOR
  branchl r12, 0x80302b90 # DevelopText_StoreBGColor
#Set Stretch
  lfs f1,DO_X_SCALE(REG_DATA)
  stfs f1,0x8(REG_DevelopText)
  lfs f1,DO_Y_SCALE(REG_DATA)
  stfs f1,0xC(REG_DevelopText)

restore
blr

CODE_START:
stw	r31, -0x4884(r13) # Replaced code line

li r3, 0
bl FN_InitShutter
li r3, 1
bl FN_InitShutter

EXIT:
