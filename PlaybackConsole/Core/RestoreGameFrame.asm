################################################################################
# Address: 8006b0dc
################################################################################

.include "Common/Common.s"
.include "PlaybackConsole/Playback.s"

# Register names
.set PlayerData,31
.set PlayerGObj,30
.set PlayerSlot,29
.set PlayerDataStatic,28
.set BufferPointer,27
.set PlayerBackup,26
.set REG_PDB_ADDR,25

################################################################################
#                   subroutine: readInputs
# description: reads inputs from Slippi for a given frame and overwrites
# memory locations
################################################################################
# Create stack frame and store link register
  backup

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
  lbz PlayerSlot,0xC(PlayerData) #loads this player slot

# Get address for static player block
  mr r3,PlayerSlot
  branchl r12, PlayerBlock_LoadStaticBlock
  mr PlayerDataStatic,r3

# get buffer pointer
  lwz REG_PDB_ADDR,primaryDataBuffer(r13)
  lwz BufferPointer,PDB_EXI_BUF_ADDR(REG_PDB_ADDR)

#Check if this player is a follower
  mr  r3,PlayerData
  branchl r12,FN_GetIsFollower
  cmpwi r3, 0
  bne Injection_Exit # Don't restore follower inputs

# Get players offset in buffer ()
  addi r4,BufferPointer, GameFrame_Start  #get to player frame data start
  lbz r5,0xC(PlayerData)                  #get player number
  mulli r5,r5,PlayerDataLength            #get players offset
  add PlayerBackup,r4,r5

CONTINUE_READ_DATA:

RestoreData:
  # clogf "[P%d] %08X", "lbz r5,0xC(PlayerData)", "mr r6, PlayerBackup", "li r7, 1"

# Restore data
  lwz r3,AnalogX(PlayerBackup)
  stw r3,0x620(PlayerData) #analog X
  lwz r3,AnalogY(PlayerBackup)
  stw r3,0x624(PlayerData) #analog Y
  lwz r3,CStickX(PlayerBackup)
  stw r3,0x638(PlayerData) #cstick X
  lwz r3,CStickY(PlayerBackup)
  stw r3,0x63C(PlayerData) #cstick Y
  lwz r3,Trigger(PlayerBackup)
  stw r3,0x650(PlayerData) #trigger
  lwz r3,Buttons(PlayerBackup)
  stw r3,0x65C(PlayerData) #buttons

# UCF uses raw controller inputs for dashback, restore x analog byte here
  load r3, 0x8046b108 # start location of circular buffer

# Get offset in raw controller input buffer
  load r4, 0x804c1f78
  lbz r4, 0x0001(r4) # this is the current index in the circular buffer
  subi r4, r4, 1
  cmpwi r4, 0
  bge+ CONTINUE_RAW_X # if our index is already 0 or greater, continue
  addi r4, r4, 5 # here our index was -1, this should wrap around to be 4
  CONTINUE_RAW_X:
  mulli r4, r4, 0x30
  add r3, r3, r4 # move to the correct start index for this index
# Get this players controller port
  lbz r4,0x618(PlayerData)
  mulli r4, r4, 0xc
  add r20, r3, r4 # move to the correct player position
# Get backed up input value
  lbz r3,AnalogRawInput(PlayerBackup)
  stb r3, 0x2(r20) #store raw x analog

Injection_Exit:
  restore             #restore registers and lr
  lbz r0, 0x2219(r31) #execute replaced code line
