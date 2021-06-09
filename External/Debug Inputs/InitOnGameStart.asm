################################################################################
# Address: INJ_InitDebugInputs
################################################################################

.include "Common/Common.s"
.include "Online/Online.s" # Required for logf buffer, should fix that
.include "./DebugInputs.s"

b CODE_START

DATA_BLRL:
blrl
.set DO_DIB_ADDR, 0
.long 0 # Buffer
.set DO_X_SCALE, DO_DIB_ADDR + 4
.float 25
.set DO_Y_SCALE, DO_X_SCALE + 4
.float 25
.set DO_COLOR, DO_Y_SCALE + 4
.byte 0,0,0,255

################################################################################
# Function: PollingHandler
################################################################################
FN_BLRL_PollingHandler:
blrl
backup

bl DATA_BLRL
mflr REG_DATA
lwz r4, DO_DIB_ADDR(REG_DATA)
lwz r3, DIB_CALLBACK_COUNT(r4)
addi r3, r3, 1
stw r3, DIB_CALLBACK_COUNT(r4)

restore
blr

################################################################################
# Function: InitColorSquare
################################################################################
.set REG_DATA, 31
.set REG_DevelopText, 30

FN_InitColorSquare:
backup

  bl DATA_BLRL
  mflr REG_DATA

#Create Rectangle
  li  r3,32
  branchl r12,HSD_MemAlloc
  mr  r8,r3
  li  r3,30 # ID
  li r4,-25 # X Pos, bottom right: 638
  li  r5,-25 # Y Pos, bottom right: 478
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
#Store Develop Text Addr
  lwz r3, DO_DIB_ADDR(REG_DATA)
  stw REG_DevelopText, DIB_DEVELOP_TEXT_ADDR(r3)

restore
blr

CODE_START:

# logf LOG_LEVEL_WARN, "Init..."

li r3, DIB_SIZE
branchl r12, HSD_MemAlloc

bl DATA_BLRL
mflr r4
stw r3, 0(r4) # Write address to static address

li r4, DIB_SIZE
branchl r12, Zero_AreaLength

bl FN_InitColorSquare

# I thought this would fire twice per frame (same as polling), but it doesn't and idk what it does
bl FN_BLRL_PollingHandler
mflr r3
branchl r12, 0x80349bf0 # SIRegisterPollingHandler

EXIT:
lfs f1, -0x5738(rtoc)