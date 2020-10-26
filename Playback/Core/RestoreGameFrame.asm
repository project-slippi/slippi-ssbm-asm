################################################################################
# Address: 8006b0dc
################################################################################

.include "Common/Common.s"
.include "Playback/Playback.s"

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
  mr  r20,r3

# Get players offset in buffer ()
  addi r4,BufferPointer, GameFrame_Start  #get to player frame data start
  lbz r5,0xC(PlayerData)                  #get player number
  mulli r5,r5,PlayerDataLength*2          #get players offset
  add r4,r4,r5
  mulli r5,r20,PlayerDataLength           #get offset based on if the player is a follower
  add PlayerBackup,r4,r5

CONTINUE_READ_DATA:

#region debug section
.if STG_DesyncDebug==1
CheckForDesync:
/*
  lis r3,0x804D
  lwz r3,0x5F90(r3)
  lwz r4,RNGSeed(PlayerBackup)
  cmpw r3,r4
  bne DesyncDetected
  */
  lfs f1,XPos(PlayerBackup)
  lfs f2,0xB0(PlayerData)
  fcmpo cr0,f1,f2
  bne DesyncDetected
  lfs f1,YPos(PlayerBackup)
  lfs f2,0xB4(PlayerData)
  fcmpo cr0,f1,f2
  bne DesyncDetected
  lfs f1,FacingDirection(PlayerBackup)
  lfs f2,0x2C(PlayerData)
  fcmpo cr0,f1,f2
  bne DesyncDetected
  lwz r4,ActionStateID(PlayerBackup)
  lwz r5,0x10(PlayerData)
  cmpw r4,r5
  bne DesyncDetected
# Get percentage
  lwz r3,Percentage(PlayerBackup)
  cmpwi r3,-1      #If this value is -1, the slp does not contain the data
  beq SkipPercentageDesyncCheck
#Check if percent is different
  stw r3,0x40(sp)  #float loads needs to be 4 byte aligned
  lfs f1,0x40(sp)
  lfs f2,0x1830(PlayerData)
  fsubs f1,f1,f2
  lfs	f2, -0x6B00 (rtoc)    #0f
  fcmpo cr0,f1,f2
  bne DesyncDetected
SkipPercentageDesyncCheck:
  b RestoreData

DesyncDetected:
  bl  DumpFrameData
.endif
#endregion

RestoreData:
# Restore data
  lis r4,0x804D
  lwz r3,RNGSeed(PlayerBackup)
  stw r3,0x5F90(r4) #RNG seed
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

# The following logic will overwrite values that will allow for resyncs. It will
# only run if the resync logic has been enabled
  lbz r3, PDB_SHOULD_RESYNC(REG_PDB_ADDR)
  cmpwi r3, 0
  beq SKIP_RESYNC

  lwz r3,XPos(PlayerBackup)
  stw r3,0xB0(PlayerData) #x position
  lwz r3,YPos(PlayerBackup)
  stw r3,0xB4(PlayerData) #y position
  lwz r3,FacingDirection(PlayerBackup)
  stw r3,0x2C(PlayerData) #facing direction
.if STG_DesyncDebug==0
  lwz r3,ActionStateID(PlayerBackup)
  stw r3,0x10(PlayerData) #animation state ID
.endif
SKIP_RESYNC:

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

# If we do not have resync logic enabled, don't try to restore percentage
  lbz r3, PDB_SHOULD_RESYNC(REG_PDB_ADDR)
  cmpwi r3, 0
  beq SkipPercentageRestore
# Get percentage
  lwz r3,Percentage(PlayerBackup)
  cmpwi r3,-1      #If this value is -1, the slp does not contain the data
  beq SkipPercentageRestore
#Check if percent is different
  stw r3,0x40(sp)  #float loads needs to be 4 byte aligned
  lfs f1,0x40(sp)
  lfs f2,0x1830(PlayerData)
  fsubs f1,f1,f2
  lfs	f2, -0x6B00 (rtoc)    #0f
  fcmpo cr0,f1,f2
  beq SkipPercentageRestore
# Apply Percentage
  mr  r3,PlayerData
  lfs f1,0x40(sp)
  lfs f2,0x1830(PlayerData)
  fsubs f1,f1,f2
  branchl r12, Damage_UpdatePercent
SkipPercentageRestore:

# Correct spawn points on the first frame
  lwz r3,frameIndex(r13)
  cmpwi r3,CONST_FirstFrameIdx
  bne SkipSpawnCorrection
# Force Direction Change
  mr  r3,PlayerData
  li  r4,0
  lfs	f1, -0x778C (rtoc)
  branchl r12, Obj_ChangeRotation_Yaw
# Update Position (Copy Physics XYZ into all ECB XYZ)
  lwz	r3, 0x00B0 (PlayerData)
  stw	r3, 0x06F4 (PlayerData)
  stw	r3, 0x070C (PlayerData)
  lwz	r3, 0x00B4 (PlayerData)
  stw	r3, 0x06F8 (PlayerData)
  stw	r3, 0x0710 (PlayerData)
  lwz	r3, 0x00B8 (PlayerData)
  stw	r3, 0x06FC (PlayerData)
  stw	r3, 0x0714 (PlayerData)
# Update Initial Y Position (AS_Entry variable)
  lfs f1,0xB4(PlayerData)
  stfs f1,0x2344(PlayerData)
# Update Collision Frame ID
  lwz	r3, -0x51F4 (r13)
  stw r3, 0x728(PlayerData)
# Update Static Player Block Coords
  lbz r3,0xC(PlayerData)
  lbz	r4, 0x221F (PlayerData)
  rlwinm	r4, r4, 29, 31, 31
  addi  r5,PlayerData,176
  branchl r12, PlayerBlock_UpdateCoords
#Update Camera Box Position
  mr  r3,PlayerGObj
  branchl r12, Camera_UpdatePlayerCameraBox
#Update Camera Box Direction Tween
  lwz r3,0x890(PlayerData)
  lfs f1,0x40(r3)     #Leftmost Bound
  stfs f1,0x2C(r3)    #Current Left Box Bound
  lfs f1,0x44(r3)     #Rightmost Bound
  stfs f1,0x30(r3)    #Current Right Box Bound
#Update Camera Position
  branchl r12, Camera_CorrectPosition
SkipSpawnCorrection:

#region debug section
.if STG_DesyncDebug==1

  b Injection_Exit

##############################################################
## Dump Frame Data Upon Desync
###############################################################
DumpFrameData:
backup

# Output data
#Divider
  bl  DividerText
  mflr r3
  crclr 6
  branchl r12, OSReport
#Frame
  bl  FrameText
  mflr  r3
  addi  r4,PlayerSlot,1
  lwz r5,frameIndex(r13)
  crclr 6
  branchl r12, OSReport
/*
#RNG Seed
  bl  RNGText
  mflr  r3
  lis r4,0x804D
  lwz r4,0x5F90(r4)
  lwz r5,RNGSeed(PlayerBackup)
  crclr 6
  branchl r12, OSReport
*/
#XPos
  bl  XPosText
  mflr  r3
  lfs f1,0xB0(PlayerData)
  lfs f2,XPos(PlayerBackup)
  crset 6
  branchl r12, OSReport
#YPos
  bl  YPosText
  mflr  r3
  lfs f1,0xB4(PlayerData)
  lfs f2,YPos(PlayerBackup)
  crset 6
  branchl r12, OSReport
#Facing Direction
  bl  FacingText
  mflr  r3
  lfs f1,0x2C(PlayerData)
  lfs f2,FacingDirection(PlayerBackup)
  crset 6
  branchl r12, OSReport
#AS
  mr r3,PlayerData
  lwz r4,0x10(PlayerData)
  addi r5,sp,0x40
  bl  GetASName
  mr r3,PlayerData
  lwz r4,ActionStateID(PlayerBackup)
  addi r5,sp,0x80
  bl  GetASName
  bl  ASText
  mflr  r3
  lwz   r4,0x10(PlayerData)
  addi  r5,sp,0x40
  lwz   r6,ActionStateID(PlayerBackup)
  addi  r7,sp,0x80
  crclr 6
  branchl r12, OSReport
#Percent
  bl  PercentText
  mflr r3
  lfs f1,0x1830(PlayerData)
  lwz r4,Percentage(PlayerBackup)
  stw r4,0x40(sp)  #float loads needs to be 4 byte aligned
  lfs f2,0x40(sp)
  crset 6
  branchl r12, OSReport

restore
blr

######################################################################

GetASName:
  backup
  mr  r31,r5
#Get animation ID from AS ID
  cmpwi r4,0x155
  blt GetASName_CommonMove
GetASName_SpecialMove:
  subi r4,r4,0x155
  lwz r5,0x20(r3)           #get special move struct
  b GetASName_GetAnimationID
GetASName_CommonMove:
  lwz r5,0x1C(r3)           #get common move struct
GetASName_GetAnimationID:
  rlwinm	r4, r4, 5, 0, 26  #get offset from AS ID
  lwzx r4,r4,r5             #get animation ID
  cmpwi r4,-1               #return "N/A" if animation not found
  beq GetASName_NoAnimation
#Get Animation Data Pointer
  branchl    r12, fetchAnimationHeader
#Get Move Name String
  lwz    r3,0x0(r3)
#Get to move name (string after ACTION_)
  subi    r3,r3,0x1
GetASName_MoveSearchLoop:
  lbzu    r6,0x1(r3)
  cmpwi   r6,0x4E         #Check for N
  bne     GetASName_MoveSearchLoop
  lbzu    r6,0x1(r3)
  cmpwi   r6,0x5F         #Check for _
  bne     GetASName_MoveSearchLoop
#Copy Move Name To Cut Off "fiagtree" Text
  subi    r4,r31,0x1
GetASName_StringCopyLoop:
  lbzu    r6,0x1(r3)
  cmpwi    r6,0x5F        #Check for Underscore
  beq    GetASName_ExitCopyLoop
  stbu    r6,0x1(r4)
  b    GetASName_StringCopyLoop
GetASName_ExitCopyLoop:
  li    r3,0x0
  stbu    r3,0x1(r4)
  b GetASName_Exit

GetASName_NoAnimation:
#Return N/A if animation isn't found
  mr  r3,r31
  bl  GetASName_NA
  mflr r4
  branchl r12, strcpy

GetASName_Exit:
  restore
  blr

GetASName_NA:
blrl
.string "N/A"
.align 2

######################################################################

  FrameText:
  blrl
  .string "P%d Frame: %d // Original // Restored
"
  .align 2

  RNGText:
  blrl
  .string "RNG Seed: 0x%X // 0x%X
"
  .align 2

  XPosText:
  blrl
  .string "X Position: %f // %f
"
  .align 2

  YPosText:
  blrl
  .string "Y Position: %f // %f
"
  .align 2

  FacingText:
  blrl
  .string "Facing Direction: %1.0f // %1.0f
"
  .align 2

  ASText:
  blrl
  .string "Action State: 0x%X %s // 0x%X %s
"
  .align 2

  PercentText:
  blrl
  .string "Percent: %1.2f //  %1.2f
"
  .align 2

  DividerText:
  blrl
  .string "------Desync Detected--------
"
  .align 2

.endif
#######################################################################
#endregion

Injection_Exit:
  restore             #restore registers and lr
  lbz r0, 0x2219(r31) #execute replaced code line
