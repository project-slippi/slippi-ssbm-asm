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
.set REG_SpentFlags,26
.set REG_CharID,25

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

  # send current animation. useful for knowing the current Wait animation
  lwz r3,0x14(REG_PlayerData)
  stw r3,0x4d(REG_Buffer)

  # send instance information
  lhz r3,0x18ec(REG_PlayerData)
  sth r3,0x51(REG_Buffer)
  lhz r3,0x2088(REG_PlayerData)
  sth r3,0x53(REG_Buffer)

  # send stored state: what a character keeps from one move to the next
  # (charges, lifts already used, Kirby's ability...). Each value is copied
  # from the character-specific vars (0x222C on), so where it is read from
  # depends on the internal char ID. Characters without one send 0. The lift
  # and float flags are bools the game only ever sets to 0 or 1, so their
  # low bit is moved into the spent bitflags as is.
  li r3,0
  stw r3,0x55(REG_Buffer)   # stored charge, spent bitflags, wall jumps, char byte
  stw r3,0x59(REG_Buffer)   # char value

  # send wall jumps used since last grounded
  lbz r3,0x1969(REG_PlayerData)
  stb r3,0x57(REG_Buffer)

  # spent bitflags start with 0x10 = aerial tether used (0x02 of 0x2228)
  lbz r3,0x2228(REG_PlayerData)
  rlwinm REG_SpentFlags,r3,3,27,27
  # and 0x20 = air item catch used (0x40 of 0x2224): Z in the air is an aerial
  # until an action change on the ground
  lbz r3,0x2224(REG_PlayerData)
  rlwimi REG_SpentFlags,r3,31,26,26

  lwz REG_CharID,0x04(REG_PlayerData) #load internal char ID
  cmpwi REG_CharID,0x00   # Mario
  beq StoredState_Mario
  cmpwi REG_CharID,0x15   # Dr. Mario
  beq StoredState_Mario
  cmpwi REG_CharID,0x03   # Donkey Kong
  beq StoredState_ChargeAt222C
  cmpwi REG_CharID,0x07   # Sheik
  beq StoredState_ChargeAt222C
  cmpwi REG_CharID,0x0D   # Samus
  beq StoredState_Samus
  cmpwi REG_CharID,0x10   # Mewtwo
  beq StoredState_Mewtwo
  cmpwi REG_CharID,0x11   # Luigi
  beq StoredState_Luigi
  cmpwi REG_CharID,0x12   # Marth
  beq StoredState_Marth
  cmpwi REG_CharID,0x1A   # Roy
  beq StoredState_Marth
  cmpwi REG_CharID,0x09   # Peach
  beq StoredState_Peach
  cmpwi REG_CharID,0x0A   # Popo
  beq StoredState_IceClimber
  cmpwi REG_CharID,0x0B   # Nana (her own event, her own flag)
  beq StoredState_IceClimber
  cmpwi REG_CharID,0x05   # Bowser
  beq StoredState_Bowser
  cmpwi REG_CharID,0x18   # Mr. Game & Watch
  beq StoredState_GameAndWatch
  cmpwi REG_CharID,0x13   # Zelda
  beq StoredState_Zelda
  cmpwi REG_CharID,0x04   # Kirby
  bne StoredState_Send

  # Kirby: the hammer lift is his own, everything else belongs to the copied ability
  lwz r3,0x2290(REG_PlayerData)   # side special lift used (Hammer)
  rlwimi REG_SpentFlags,r3,1,30,30
  lwz REG_CharID,0x2238(REG_PlayerData)   # copied ability as an internal char ID, 4 = none
  stb REG_CharID,0x58(REG_Buffer)
  cmpwi REG_CharID,0x03   # Donkey Kong
  beq StoredState_KirbyDK
  cmpwi REG_CharID,0x0D   # Samus
  beq StoredState_KirbySamus
  cmpwi REG_CharID,0x10   # Mewtwo
  beq StoredState_KirbyMewtwo
  cmpwi REG_CharID,0x07   # Sheik
  beq StoredState_KirbySheik
  cmpwi REG_CharID,0x05   # Bowser
  beq StoredState_KirbyBowser
  cmpwi REG_CharID,0x09   # Peach
  beq StoredState_KirbyPeach
  cmpwi REG_CharID,0x0A   # Popo
  beq StoredState_KirbyIceClimber
  cmpwi REG_CharID,0x0B   # Nana
  bne StoredState_Send
StoredState_KirbyIceClimber:
  lwz r3,0x22F0(REG_PlayerData)   # neutral special lift used (Ice Shot)
  rlwimi REG_SpentFlags,r3,0,31,31
  b StoredState_Send
StoredState_KirbyPeach:
  lwz r3,0x22F8(REG_PlayerData)   # neutral special lift used (Toad)
  rlwimi REG_SpentFlags,r3,0,31,31
  b StoredState_Send
StoredState_KirbyBowser:
  lwz r3,0x22B0(REG_PlayerData)   # Fire Breath fuel (float)
  stw r3,0x59(REG_Buffer)
  b StoredState_Send
StoredState_KirbyDK:
  lwz r3,0x22E8(REG_PlayerData)   # Giant Punch charge
  stb r3,0x55(REG_Buffer)
  b StoredState_Send
StoredState_KirbySamus:
  lwz r3,0x22D4(REG_PlayerData)   # Charge Shot charge
  stb r3,0x55(REG_Buffer)
  b StoredState_Send
StoredState_KirbyMewtwo:
  lwz r3,0x22C8(REG_PlayerData)   # Shadow Ball charge
  stb r3,0x55(REG_Buffer)
  b StoredState_Send
StoredState_KirbySheik:
  lwz r3,0x22E0(REG_PlayerData)   # needles held
  stb r3,0x55(REG_Buffer)
  b StoredState_Send

StoredState_Mario:
  lwz r3,0x2238(REG_PlayerData)   # side special lift used (Cape)
  rlwimi REG_SpentFlags,r3,1,30,30
  lwz r3,0x2234(REG_PlayerData)   # down special lift used (Tornado)
  rlwimi REG_SpentFlags,r3,2,29,29
  b StoredState_Send
StoredState_ChargeAt222C:
  lwz r3,0x222C(REG_PlayerData)   # DK: Giant Punch charge // Sheik: needles held
  stb r3,0x55(REG_Buffer)
  b StoredState_Send
StoredState_Samus:
  lwz r3,0x2230(REG_PlayerData)   # Charge Shot charge
  stb r3,0x55(REG_Buffer)
  b StoredState_Send
StoredState_Mewtwo:
  lwz r3,0x2234(REG_PlayerData)   # Shadow Ball charge
  stb r3,0x55(REG_Buffer)
  lwz r3,0x223C(REG_PlayerData)   # side special lift used (Confusion)
  rlwimi REG_SpentFlags,r3,1,30,30
  b StoredState_Send
StoredState_Luigi:
  lwz r3,0x222C(REG_PlayerData)   # down special lift used (Cyclone)
  rlwimi REG_SpentFlags,r3,2,29,29
  b StoredState_Send
StoredState_Marth:
  lwz r3,0x222C(REG_PlayerData)   # side special lift used (Dancing Blade / Double-Edge Dance)
  rlwimi REG_SpentFlags,r3,1,30,30
  b StoredState_Send
StoredState_Peach:
  lwz r3,0x2240(REG_PlayerData)   # neutral special lift used (Toad)
  rlwimi REG_SpentFlags,r3,0,31,31
  lwz r3,0x222C(REG_PlayerData)   # 1 = can float, so 0x08 = float used is its inverse
  xori r3,r3,1
  rlwimi REG_SpentFlags,r3,3,28,28
  lwz r3,0x2230(REG_PlayerData)   # float frames left (float)
  stw r3,0x59(REG_Buffer)
  b StoredState_Send
StoredState_IceClimber:
  lwz r3,0x224C(REG_PlayerData)   # neutral special lift used (Ice Shot)
  rlwimi REG_SpentFlags,r3,0,31,31
  b StoredState_Send
StoredState_Bowser:
  lwz r3,0x222C(REG_PlayerData)   # Fire Breath fuel (float)
  stw r3,0x59(REG_Buffer)
  b StoredState_Send
StoredState_Zelda:
  # the needles Sheik holds while Zelda is in play: Sheik is this port's other
  # entity, asleep. Static player block (0x80453080 + 0xE90 per port):
  # transformed[1] (0x0D) is the index of the entity not in play, the entity
  # GObjs are at 0xB0 and 0xB4.
  load r3,0x80453080
  mulli r4,REG_PlayerSlot,0xE90
  add r3,r3,r4
  lbz r4,0x0D(r3)
  slwi r4,r4,2
  addi r4,r4,0xB0
  lwzx r3,r3,r4           # the other entity's GObj
  cmpwi r3,0
  beq StoredState_Send
  lwz r3,0x2C(r3)         # its character data
  lwz r4,0x04(r3)
  cmpwi r4,0x07           # Sheik
  bne StoredState_Send
  lwz r3,0x222C(r3)       # needles held
  stb r3,0x55(REG_Buffer)
  b StoredState_Send
StoredState_GameAndWatch:
  lwz r3,0x2238(REG_PlayerData)   # Oil Panic shots absorbed
  stb r3,0x55(REG_Buffer)
  lwz r3,0x222C(REG_PlayerData)   # last Judge number in the low nibble
  lwz r4,0x2230(REG_PlayerData)   # the one before it in the high nibble
  rlwimi r3,r4,4,24,27
  stb r3,0x58(REG_Buffer)
  lwz r3,0x223C(REG_PlayerData)   # Oil Panic absorbed damage (int)
  stw r3,0x59(REG_Buffer)

StoredState_Send:
  stb REG_SpentFlags,0x56(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,(GAME_POST_FRAME_PAYLOAD_LENGTH+1)
  stw REG_BufferOffset,bufferOffset(r13)

Injection_Exit:
  restore
  lwz r0, 0x001C (sp)
