################################################################################
# Address: 8006da34
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

################################################################################
# Routine: SendGamePostFrame
# ------------------------------------------------------------------------------
# Description: Gets information relevant to calculating stats and writes
# it to Slippi device
################################################################################

.set REG_PlayerData,31
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

# send OnPostFrameUpdate event code
  li r3, CMD_POST_FRAME
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

# send player data
  lwz r3,0x04(REG_PlayerData) #load internal char ID
  stb r3,0x07(REG_Buffer)
  lwz r3,0x10(REG_PlayerData) #load action state ID
  sth r3,0x08(REG_Buffer)
  lwz r3,0xB0(REG_PlayerData) #load x coord
  stw r3,0x0A(REG_Buffer)
  lwz r3,0xB4(REG_PlayerData) #load y coord
  stw r3,0x0E(REG_Buffer)
  lwz r3,0x2C(REG_PlayerData) #load facing direction
  stw r3,0x12(REG_Buffer)
  lwz r3,0x1830(REG_PlayerData) #load current damage
  stw r3,0x16(REG_Buffer)
  lwz r3,0x1998(REG_PlayerData) #load shield health
  stw r3,0x1A(REG_Buffer)
  lwz r3,0x208C(REG_PlayerData) #load last attack ID hit by
  stb r3,0x1E(REG_Buffer)
  lhz r3,0x2090(REG_PlayerData) #load combo count
  stb r3,0x1F(REG_Buffer)
  lwz r3,0x18C4(REG_PlayerData) #load player slot who last hit this player
  stb r3,0x20(REG_Buffer)

# send stocks remaining
  mr  r3,REG_PlayerSlot
  branchl r12,PlayerBlock_LoadRemainingStocks
  stb r3,0x21(REG_Buffer)

# send AS frame
  lwz r3,0x894(REG_PlayerData)
  stw r3,0x22(REG_Buffer)

# send bitflags
  lbz r3,0x2218(REG_PlayerData)   #0x10 = isReflectActive
  stb r3,0x26(REG_Buffer)
  lbz r3,0x221A(REG_PlayerData)   #0x04 = HasIntangOrInvinc // 0x08 = isFastFalling // 0x20 = isHitlag
  stb r3,0x27(REG_Buffer)
  lbz  r3,0x221B(REG_PlayerData)  #0x80 = isShieldActive
  stb r3,0x28(REG_Buffer)
  lbz r3,0x221C(REG_PlayerData)   #0x2 = isHitstun // 0x4 = owners detection hitbox touching shield bubble // 0x20 = Powershield Active Bool
  stb r3,0x29(REG_Buffer)
  lbz r3,0x221F(REG_PlayerData)   #0x80 = isOffscreen // 0x40 = isDead // 0x20 =  // 0x10 = inSleep // 0x8 = isFollower
  stb r3,0x2A(REG_Buffer)

# send misc AS variable (is histun frames left when offset 0x221C has hitstun bool enabled)
  lwz r3,0x2340(REG_PlayerData)
  stw r3,0x2B(REG_Buffer)

# send ground/air state
  lwz r3,0xE0(REG_PlayerData)
  stb r3,0x2F(REG_Buffer)

# send ground ID
  lwz r3,0x83C(REG_PlayerData)
  sth r3,0x30(REG_Buffer)

# send number of jumps remaining
  lbz r3,0x1968(REG_PlayerData)
  lwz r4,0x168(REG_PlayerData)
  sub r3,r4,r3
  stb r3,0x32(REG_Buffer)

# send status of lcancel. 0 = none, 1 = successful lcancel, 2 = unsuccessful lcancel
  lbz r3,LCancelStatus(REG_PlayerData)
  stb r3,0x33(REG_Buffer)

# send hurtbox collision status (0 = vulnerable, 1 = invulnerable, 2 = intangible)
  lwz r3,0x1988(REG_PlayerData)     #Move-induced collision state has priority over game-induced
  cmpwi r3,0
  bne HurtboxCollision_Send
  lwz r3,0x198C(REG_PlayerData)
  HurtboxCollision_Send:
  stb r3,0x34(REG_Buffer)

  # send self-induced air x speed
  lwz r3,0x80(REG_PlayerData)
  stw r3,0x35(REG_Buffer)

  # send self-induced y speed
  lwz r3,0x84(REG_PlayerData)
  stw r3,0x39(REG_Buffer)

  # send attack-based x speed
  lwz r3,0x8c(REG_PlayerData)
  stw r3,0x3d(REG_Buffer)

  # send attack-based y speed
  lwz r3,0x90(REG_PlayerData)
  stw r3,0x41(REG_Buffer)

  # send self-induced ground x speed
  lwz r3,0xec(REG_PlayerData)
  stw r3,0x45(REG_Buffer)

  # send hitlag frames left (stored internally as a float)
  lwz r3,0x195c(REG_PlayerData)
  stw r3,0x49(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,(GAME_POST_FRAME_PAYLOAD_LENGTH+1)
  stw REG_BufferOffset,bufferOffset(r13)

Injection_Exit:
  restore
  lwz r0, 0x001C (sp)
