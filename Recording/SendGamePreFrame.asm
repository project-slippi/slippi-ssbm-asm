################################################################################
# Address: 8006b0dc
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

################################################################################
# Routine: SendGamePreFrame
# ------------------------------------------------------------------------------
# Description: Gets information relevant to playing back a replay and writes
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

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
# get player slot
  lbz REG_PlayerSlot,0xC(REG_PlayerData)
# get current offset in buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset

# send OnPreFrameUpdate event code
  li r3, CMD_PRE_FRAME
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

# send random seed
  lis r3, 0x804D
  lwz r3, 0x5F90(r3) #load random seed
  stw r3,0x7(REG_Buffer)

# send player data
  lwz r3,0x10(REG_PlayerData) #load action state ID
  sth r3,0x0B(REG_Buffer)
  lwz r3,0xB0(REG_PlayerData) #load x coord
  stw r3,0x0D(REG_Buffer)
  lwz r3,0xB4(REG_PlayerData) #load y coord
  stw r3,0x11(REG_Buffer)
  lwz r3,0x2C(REG_PlayerData) #load facing direction
  stw r3,0x15(REG_Buffer)
  lwz r3,0x620(REG_PlayerData) #load Joystick X axis
  stw r3,0x19(REG_Buffer)
  lwz r3,0x624(REG_PlayerData) #load Joystick Y axis
  stw r3,0x1D(REG_Buffer)
  lwz r3,0x638(REG_PlayerData) #load c-stick X axis
  stw r3,0x21(REG_Buffer)
  lwz r3,0x63C(REG_PlayerData) #load c-stick Y axis
  stw r3,0x25(REG_Buffer)
  lwz r3,0x650(REG_PlayerData) #load analog trigger input
  stw r3,0x29(REG_Buffer)
  lwz r3,0x65C(REG_PlayerData) #load buttons pressed this frame
  stw r3,0x2D(REG_Buffer)

# get raw controller inputs
  lis r3, 0x804C
  ori r3, r3, 0x1FAC
  mulli r4, REG_PlayerSlot, 0x44
  add r4, r3, r4
# send raw controller inputs
  lhz r3,0x2(r4)           #load constant button presses
  sth r3,0x31(REG_Buffer)
  lwz r3,0x30(r4)          #load l analog trigger
  stw r3,0x33(REG_Buffer)
  lwz r3,0x34(r4)          #load r analog trigger
  stw r3,0x37(REG_Buffer)

# get raw x analog input for UCF. The game has a 5 frame circular buffer
# where it stores raw inputs for previous frames, we must fetch the location
# where the current frame's value is stored
# TODO: If we ever switch to 2f dashback, we probably won't need this
  load r3,0x8046b108  # start location of circular buffer
  load r4,0x804c1f78
  lbz r4, 0x0001(r4) # this is the current index in the circular buffer
  subi r4, r4, 1
  cmpwi r4, 0
  bge+ CONTINUE_RAW_X # if our index is already 0 or greater, continue
  addi r4, r4, 5 # here our index was -1, this should wrap around to be 4
CONTINUE_RAW_X:
  mulli r4, r4, 0x30
  add r3, r3, r4 # move to the correct start index for this index

  mulli r4, REG_PlayerSlot, 0xc
  add r3, r3, r4 # move to the correct player position

  lbz r3, 0x2(r3) #load raw x analog
  stb r3,0x3B(REG_Buffer)

# Send player's percent
  lwz r3,0x1830(r31)
  stw r3,0x3C(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,(GAME_PRE_FRAME_PAYLOAD_LENGTH+1)
  stw REG_BufferOffset,bufferOffset(r13)

Injection_Exit:
  restore
  lbz r0, 0x2219(r31) #execute replaced code line
