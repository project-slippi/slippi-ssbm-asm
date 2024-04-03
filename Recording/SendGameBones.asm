################################################################################
# Address: 8006da38
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

################################################################################
# Routine: SendGameBones
# ------------------------------------------------------------------------------
# Description: Sends bone data to be stored in replay
################################################################################

.set REG_PlayerData,31
.set REG_FighterGobj,30
.set REG_Buffer,29
.set REG_BufferOffset,28
.set REG_PlayerSlot,27

backup

# Check if VS Mode
  branchl r12,FN_ShouldRecord
  cmpwi r3,0x0
  beq Injection_Exit

# check if this character is in sleep
  lbz r3,0x221F(REG_PlayerData)
  rlwinm. r3,r3,0,27,27
  bne Injection_Exit

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
  lbz REG_PlayerSlot,0xC(REG_PlayerData)      #loads this player slot
# get current offset in buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset

#------------- Start bones extract -------------

# send bones extract code
  li r3, CMD_BONES_EXTRACT
  stb r3,0x0(REG_Buffer)

# send frame count
  lwz r3,frameIndex(r13)
  stw r3,0x1(REG_Buffer)

# send playerslot
  stb REG_PlayerSlot,0x5(REG_Buffer)

# send isFollowerBool
  mr  r3,REG_PlayerData
  branchl r12,FN_GetIsFollower
  stb r3,0x6(REG_Buffer)

# send char id
  lwz r3,0x04(REG_PlayerData) #load internal char ID
  stb r3,0x07(REG_Buffer)

  # Extract bone information
  lwz r3, 0x28(REG_FighterGobj) # Get JObj
  li r4, 0
  addi r5, REG_Buffer, 0xA
  bl JOBJ_ExtractBones

  # Store bone count
  sth r3, 0x8(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,(GAME_BONES_EXTRACT_PAYLOAD_LENGTH+1)
  stw REG_BufferOffset,bufferOffset(r13)

  b Injection_Exit

##############################

JOBJ_ExtractBones:
# r3 = jobj
# r4 = count
# r5 = buffer_addr

.set REG_JObj, 31
.set REG_Count, 30
.set REG_BufAddr, 29

# backup jobj
mflr r0
stw    r0, 0x0004 (sp)
stwu    sp, -0x001C (sp)
stw    REG_JObj, 0x0014 (sp)
stw REG_Count, 0x10(sp)
stw REG_BufAddr, 0x0C(sp)
mr REG_JObj,r3
mr REG_Count,r4
mr REG_BufAddr,r5

# output all jobj values
lwz r3, 0x44(REG_JObj)
stw r3, 0x0(REG_BufAddr) # RX
lwz r3, 0x54(REG_JObj)
stw r3, 0x4(REG_BufAddr) # RY
lwz r3, 0x64(REG_JObj)
stw r3, 0x8(REG_BufAddr) # RZ
lwz r3, 0x2C(REG_JObj)
stw r3, 0xC(REG_BufAddr) # SX
lwz r3, 0x30(REG_JObj)
stw r3, 0x10(REG_BufAddr) # SY
lwz r3, 0x34(REG_JObj)
stw r3, 0x14(REG_BufAddr) # SZ
lwz r3, 0x38(REG_JObj)
stw r3, 0x18(REG_BufAddr) # TX
lwz r3, 0x3C(REG_JObj)
stw r3, 0x1C(REG_BufAddr) # TY
lwz r3, 0x40(REG_JObj)
stw r3, 0x20(REG_BufAddr) # TZ

addi REG_Count, REG_Count, 1
addi REG_BufAddr, REG_BufAddr, 9 * 4

# run on child
lwz r3,0x10(REG_JObj)
mr r4, REG_Count
mr r5, REG_BufAddr
cmpwi r3,0
beq 0x10
bl  JOBJ_ExtractBones
mr REG_Count, r3
mr REG_BufAddr, r4

# run on sibling
lwz r3,0x8(REG_JObj)
mr r4, REG_Count
mr r5, REG_BufAddr
cmpwi r3,0
beq 0x10
bl  JOBJ_ExtractBones
mr REG_Count, r3
mr REG_BufAddr, r4

# Return values and exit function
mr r3, REG_Count
mr r4, REG_BufAddr
lwz    REG_JObj, 0x0014 (sp)
lwz REG_Count, 0x10(sp)
lwz REG_BufAddr, 0x0C(sp)
lwz r0,0x20(sp)
addi    sp, sp, 0x001C
mtlr r0
blr

##############################

Injection_Exit:
  restore
  lwz r0, 0x001C (sp)
  lwz	r31, 0x0014 (sp)