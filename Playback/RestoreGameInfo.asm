#To be inserted at 8016e74c
################################################################################
#                      Inject at address 8016e74c
# Function is StartMelee and we are loading game information right before
# it gets read to initialize the match
################################################################################
.include "../Common/Common.s"
.include "Playback.s"

# Register names
.set BufferPointer,30

################################################################################
#                   subroutine: gameInfoLoad
# description: reads game info from slippi and loads those into memory
# addresses that will be used
################################################################################
# create stack frame and store link register
  backup

# allocate memory for the gameframe buffer used here and in ReceiveGameFrame
  li  r3,(PlayerDataLength*8)+FrameHeaderLength
  branchl r12,0x8037f1e4
  mr  BufferPointer,r3
  stw BufferPointer,frameDataBuffer(r13)

# allocate memory for the secondaryDmaBuffer used in RestoreStockSteal
  li  r3,64
  branchl r12,0x8037f1e4
  stw r3,secondaryDmaBuffer(r13)

# get the game info data
REQUEST_DATA:
# request game information from slippi
  li r3,0x75        # store game info request ID
  stb r3,0x0(BufferPointer)
# Transfer buffer over DMA
  mr r3,BufferPointer   #Buffer Pointer
  li  r4,0x1            #Buffer Length
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
RECEIVE_DATA:
# Transfer buffer over DMA
  mr  r3,BufferPointer
  li  r4,GameInfoLength     #Buffer Length
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer
# Check if successful
  lbz r3,0x0(BufferPointer)
  cmpwi r3, 1
  beq READ_DATA
# Wait a frame before trying again
  branchl r12,0x8034f314 #VIWaitForRetrace
  b REQUEST_DATA

READ_DATA:
  lwz r3,InfoRNGSeed(BufferPointer)
  lis r4, 0x804D
  stw r3, 0x5F90(r4) #store random seed

#------------- GAME INFO BLOCK -------------
# this iterates through the static game info block that is used to pull data
# from to initialize the game. it reads the whole thing from slippi and writes
# it back to memory. (0x138 bytes long)
  mr  r3,r31                        #Match setup struct
  addi r4,BufferPointer,MatchStruct #Match info from slippi
  li  r5,0x138                      #Match struct length
  branchl r12,0x800031f4

#------------- OTHER INFO -------------
# write UCF toggle bytes
  subi r20,rtoc,UCFBools             #Get UCF toggles in game memory
  addi r21,BufferPointer,UCFToggles  #Get UCF toggles in buffer
  li  r22,0                          #Init loop
UCF_LOOP:
  mulli r3,r22,0x8          #each player's ucf toggle is 8 bytes long (thanks FM)
  lwzx  r3,r3,r21           #get ucf toggle value
  stbx  r3,r22,r20          #store to game memory
  addi  r22,r22,1
  cmpwi r22,4
  blt UCF_LOOP

#------------- RESTORE NAMETAGS ------------
# Loop through players 1-4 and restore their nametag data
# r31 contains the match struct fed into StartMelee. We'll
# be using this to restore each player's nametag slot

# Offsets
.set PlayerInfoStart,96       #player data starts in match struct
.set PlayerInfoLength,36      #length of each player's data
.set PlayerStatus,0x1         #offset of players in-game status
.set Nametag,0xA              #offset of the nametag ID in the player's data
# Constants
.set CharactersToCopy, 8 *2
# Registers
.set REG_LoopCount,20
.set REG_PlayerInfoStart,21
.set REG_CurrentPlayerData,22
.set REG_NametagID,23

# Init loop
  li  REG_LoopCount,0                               #init loop count
  addi REG_PlayerInfoStart,r31,PlayerInfoStart     #player data start in match struct
RESTORE_GAME_INFO_NAMETAG_LOOP:
# Get players data
  mulli REG_CurrentPlayerData,REG_LoopCount,PlayerInfoLength
  add REG_CurrentPlayerData,REG_CurrentPlayerData,REG_PlayerInfoStart
# Check if player is in game && human
  lbz r3,PlayerStatus(REG_CurrentPlayerData)
  cmpwi r3,0x0
  bne RESTORE_GAME_INFO_NAMETAG_NO_TAG
# Check if player has a nametag
  lbz r3,Nametag(REG_CurrentPlayerData)
  cmpwi r3,0x78
  beq RESTORE_GAME_INFO_NAMETAG_NO_TAG
RESTORE_GAME_INFO_NAMETAG_HAS_TAG:
# Save nametag ID
  mr REG_NametagID,r3
# Set nametag as active
  branchl r12,0x80237a04
# Get nametag text pointer
  mr  r3,REG_NametagID
  branchl r12,0x8015cc9c
  addi r3,r3,0x198
# Get players nametag
  addi r4,BufferPointer,NametagData       #Start of nametag data
  mulli r5,REG_LoopCount,CharactersToCopy #This players nametag data
  add r4,r4,r5
# Check if nametag data is empty (old replays have no data here)
  lbz r5,0x(r4)
  cmpwi r5,0x0
  bne RESTORE_GAME_INFO_NAMETAG_COPY
# Nametag was not backed up, give player a null nametag ID
  li  r3,0x78
  stb r3,Nametag(REG_CurrentPlayerData)
  b RESTORE_GAME_INFO_NAMETAG_INC_LOOP
RESTORE_GAME_INFO_NAMETAG_COPY:
# Copy backed up nametag to it
  li  r5,CharactersToCopy
  branchl r12,0x800031f4
  b RESTORE_GAME_INFO_NAMETAG_INC_LOOP
RESTORE_GAME_INFO_NAMETAG_NO_TAG:
RESTORE_GAME_INFO_NAMETAG_INC_LOOP:
# Increment Loop
  addi REG_LoopCount,REG_LoopCount,1
  cmpwi REG_LoopCount,4
  blt RESTORE_GAME_INFO_NAMETAG_LOOP

Injection_Exit:
restore
lis r3, 0x8017 #execute replaced code line
