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

# where a stored state value goes. The lifts are their bit number in the
# spent bitflags
.set STORED_NEUTRAL_LIFT,0
.set STORED_SIDE_LIFT,1
.set STORED_DOWN_LIFT,2
.set STORED_CHARGE,3      # stored charge byte
.set STORED_CHAR_VALUE,4  # char value word

.macro storedState charID, kind, offset
  .byte \charID, \kind
  .short \offset
.endm

b CODE_START

STORED_STATE_TABLE_BLRL:
  blrl
  # every value a character keeps from one move to the next, read as a word
  # from its character-specific vars (0x222C on). Kirby's copy of an ability
  # is keyed by 0x80 | the ability's internal char ID
  storedState 0x00, STORED_SIDE_LIFT, 0x2238      # Mario: Cape
  storedState 0x00, STORED_DOWN_LIFT, 0x2234      # Mario: Tornado
  storedState 0x15, STORED_SIDE_LIFT, 0x2238      # Dr. Mario: Cape
  storedState 0x15, STORED_DOWN_LIFT, 0x2234      # Dr. Mario: Tornado
  storedState 0x03, STORED_CHARGE, 0x222C         # Donkey Kong: Giant Punch charge
  storedState 0x07, STORED_CHARGE, 0x222C         # Sheik: needles held
  storedState 0x0D, STORED_CHARGE, 0x2230         # Samus: Charge Shot charge
  storedState 0x10, STORED_CHARGE, 0x2234         # Mewtwo: Shadow Ball charge
  storedState 0x10, STORED_SIDE_LIFT, 0x223C      # Mewtwo: Confusion
  storedState 0x11, STORED_DOWN_LIFT, 0x222C      # Luigi: Cyclone
  storedState 0x12, STORED_SIDE_LIFT, 0x222C      # Marth: Dancing Blade
  storedState 0x1A, STORED_SIDE_LIFT, 0x222C      # Roy: Double-Edge Dance
  storedState 0x09, STORED_NEUTRAL_LIFT, 0x2240   # Peach: Toad
  storedState 0x09, STORED_CHAR_VALUE, 0x2230     # Peach: float frames left (float)
  storedState 0x0A, STORED_NEUTRAL_LIFT, 0x224C   # Popo: Ice Shot
  storedState 0x0B, STORED_NEUTRAL_LIFT, 0x224C   # Nana: Ice Shot (her own event, her own flag)
  storedState 0x05, STORED_CHAR_VALUE, 0x222C     # Bowser: Fire Breath fuel (float)
  storedState 0x18, STORED_CHARGE, 0x2238         # Mr. Game & Watch: Oil Panic shots absorbed
  storedState 0x18, STORED_CHAR_VALUE, 0x223C     # Mr. Game & Watch: Oil Panic absorbed damage (int)
  storedState 0x04, STORED_SIDE_LIFT, 0x2290      # Kirby: Hammer
  storedState 0x83, STORED_CHARGE, 0x22E8         # Kirby as Donkey Kong: Giant Punch charge
  storedState 0x87, STORED_CHARGE, 0x22E0         # Kirby as Sheik: needles held
  storedState 0x8D, STORED_CHARGE, 0x22D4         # Kirby as Samus: Charge Shot charge
  storedState 0x90, STORED_CHARGE, 0x22C8         # Kirby as Mewtwo: Shadow Ball charge
  storedState 0x89, STORED_NEUTRAL_LIFT, 0x22F8   # Kirby as Peach: Toad
  storedState 0x8A, STORED_NEUTRAL_LIFT, 0x22F0   # Kirby as Popo: Ice Shot
  storedState 0x8B, STORED_NEUTRAL_LIFT, 0x22F0   # Kirby as Nana: Ice Shot
  storedState 0x85, STORED_CHAR_VALUE, 0x22B0     # Kirby as Bowser: Fire Breath fuel (float)
  storedState 0xFF, 0, 0                          # end of table

CODE_START:
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
  # (charges, lifts already used, Kirby's ability...). Characters without one
  # send 0, and so does Zelda even when her sleeping Sheik still holds needles.
  # The lift and float flags are bools the game only ever sets to 0 or 1, so
  # only their low bit is moved into the spent bitflags.
  li r3,0
  stw r3,0x55(REG_Buffer)   # stored charge, spent bitflags, wall jumps, char byte
  stw r3,0x59(REG_Buffer)   # char value

  # send wall jumps used since last grounded
  lbz r3,0x1969(REG_PlayerData)
  stb r3,0x57(REG_Buffer)

  # spent bitflags start with 0x10 = aerial tether used (0x02 of 0x2228)
  lbz r3,0x2228(REG_PlayerData)
  rlwinm REG_SpentFlags,r3,3,27,27
  # and 0x20 = air item catch used (0x40 of 0x2224): no item can be caught in
  # the air until an action change on the ground
  lbz r3,0x2224(REG_PlayerData)
  rlwimi REG_SpentFlags,r3,31,26,26

  # copy every table entry for this character
  lwz REG_CharID,0x04(REG_PlayerData) #load internal char ID
StoredState_Lookup:
  bl STORED_STATE_TABLE_BLRL
  mflr r4
StoredState_NextEntry:
  lbz r5,0x0(r4)    # char ID
  cmpwi r5,0xFF
  beq StoredState_CheckSpecial
  lbz r6,0x1(r4)    # where it goes
  lhz r7,0x2(r4)    # where it is read from
  addi r4,r4,4
  cmpw r5,REG_CharID
  bne StoredState_NextEntry
  lwzx r3,REG_PlayerData,r7
  cmpwi r6,STORED_CHARGE
  blt StoredState_Lift
  beq StoredState_Charge
StoredState_CharValue:
  stw r3,0x59(REG_Buffer)
  b StoredState_NextEntry
StoredState_Charge:
  stb r3,0x55(REG_Buffer)
  b StoredState_NextEntry
StoredState_Lift:
  clrlwi r3,r3,31
  slw r3,r3,r6
  or REG_SpentFlags,REG_SpentFlags,r3
  b StoredState_NextEntry

  # then what the table can't hold
StoredState_CheckSpecial:
  cmpwi REG_CharID,0x04   # Kirby
  beq StoredState_Kirby
  cmpwi REG_CharID,0x09   # Peach
  beq StoredState_Peach
  cmpwi REG_CharID,0x18   # Mr. Game & Watch
  bne StoredState_Send

StoredState_GameWatch:
  lwz r3,0x222C(REG_PlayerData)   # last Judge number in the low nibble
  lwz r4,0x2230(REG_PlayerData)   # the one before it in the high nibble
  rlwimi r3,r4,4,24,27
  stb r3,0x58(REG_Buffer)
  b StoredState_Send
StoredState_Kirby:
  # the hammer is his own, everything else belongs to the copied ability
  lwz REG_CharID,0x2238(REG_PlayerData)   # copied ability as an internal char ID, 4 = none
  stb REG_CharID,0x58(REG_Buffer)
  ori REG_CharID,REG_CharID,0x80
  b StoredState_Lookup
StoredState_Peach:
  lwz r3,0x222C(REG_PlayerData)   # 1 = can float, so 0x08 = float used is its inverse
  xori r3,r3,1
  rlwimi REG_SpentFlags,r3,3,28,28

StoredState_Send:
  stb REG_SpentFlags,0x56(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,(GAME_POST_FRAME_PAYLOAD_LENGTH+1)
  stw REG_BufferOffset,bufferOffset(r13)

Injection_Exit:
  restore
  lwz r0, 0x001C (sp)
