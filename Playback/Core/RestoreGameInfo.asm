################################################################################
# Address: 8016e74c
################################################################################

################################################################################
#                      Inject at address 8016e74c
# Function is StartMelee and we are loading game information right before
# it gets read to initialize the match
################################################################################
.include "Common/Common.s"
.include "Playback/Playback.s"
.include "Playback/Core/RestoreInitialRNG.s"

# Register names
.set BufferPointer,30
.set REG_GeckoBuffer,29
.set REG_DirectoryBuffer,28

################################################################################
#                   subroutine: gameInfoLoad
# description: reads game info from slippi and loads those into memory
# addresses that will be used
################################################################################
# create stack frame and store link register
  backup

# allocate memory for directory buffer
  li r3, PDB_SIZE
  branchl r12, HSD_MemAlloc
  mr REG_DirectoryBuffer, r3
  stw REG_DirectoryBuffer, primaryDataBuffer(r13) # Store directory buffer location
  li r4, PDB_SIZE
  branchl r12, Zero_AreaLength

# allocate memory for the gameframe buffer used here and in ReceiveGameFrame
  li  r3,EXIBufferLength
  branchl r12, HSD_MemAlloc
  mr  BufferPointer,r3
  stw BufferPointer,PDB_EXI_BUF_ADDR(REG_DirectoryBuffer)

# allocate memory for the Secondary Buffer used in RestoreStockSteal
  li  r3,64
  branchl r12, HSD_MemAlloc
  stw r3,PDB_SECONDARY_EXI_BUF_ADDR(REG_DirectoryBuffer)

# get the game info data
REQUEST_DATA:
# request game information from slippi
  li r3,CMD_GET_GAME_INFO        # store game info request ID
  stb r3,0x0(BufferPointer)

# write memory locations to preserve when doing mem savestates
  addi r3, REG_DirectoryBuffer, PDB_SFXDB_START
  stw r3, 0x1(BufferPointer)
  li r3, SFXDB_SIZE + 4 # include the latest frame which follows SFXDB
  stw r3, 0x5(BufferPointer)
  li r3, 0
  stw r3, 0x9(BufferPointer)

# Transfer buffer over DMA
  mr r3,BufferPointer   #Buffer Pointer
  li  r4,0xD            #Buffer Length
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
  branchl r12, VIWaitForRetrace
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
  branchl r12, memcpy

# nullify function pointers
# Dolphin v2.1.0 had an issue where it put something in the game start callback
# which would pause the game. By clearing these, we avoid that issue with 2.1.0
  addi r3, r31, 0x40
  li r4, 0x1C
  branchl r12, Zero_AreaLength

#------------- OTHER INFO -------------
# write UCF toggle bytes
  subi r23,rtoc,DashbackOptions #Prepare game memory dashback toggle address
  subi r20,rtoc,ShieldDropOptions #Prepare game memory shield drop toggle address
  addi r21,BufferPointer,UCFToggles  #Get UCF toggles in buffer
  li  r22,0                          #Init loop
UCF_LOOP:
  mulli r4,r22,0x8          #each player's ucf toggle is 8 bytes long (thanks FM)
  lwzx  r3,r4,r21           #get dashback toggle from
  stbx  r3,r22,r23          #store to dashback
  addi  r4,r4,0x4
  lwzx  r3,r4,r21
  stbx  r3,r22,r20
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
  branchl r12, Nametag_SetNameAsInUse
# Get nametag text pointer
  mr  r3,REG_NametagID
  branchl r12, Nametag_GetNametagBlock
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
  branchl r12, memcpy
  b RESTORE_GAME_INFO_NAMETAG_INC_LOOP
RESTORE_GAME_INFO_NAMETAG_NO_TAG:
RESTORE_GAME_INFO_NAMETAG_INC_LOOP:
# Increment Loop
  addi REG_LoopCount,REG_LoopCount,1
  cmpwi REG_LoopCount,4
  blt RESTORE_GAME_INFO_NAMETAG_LOOP

#Restore PALToggle byte
  lbz r3,PALBool(BufferPointer)
  stb r3,PALToggle(rtoc)

#Restore PSPreloadToggle byte
  lbz r3,PSPreloadBool(BufferPointer)
  stb r3,PSPreloadToggle(rtoc)

#Restore FrozenPS byte
# TODO: This probably is no longer necessary with dynamic gecko codes
  lbz r3,FrozenPSBool(BufferPointer)
  stb r3,FSToggle(rtoc)

# Get bool for whether resync logic should be used
  lbz r3,ShouldResyncBool(BufferPointer)
  stb r3,PDB_SHOULD_RESYNC(REG_DirectoryBuffer)

#--------------- Apply Dynamic Gecko Codes ---------------------
# Step 1: Grab size of gecko code list and create a buffer to store them
  # TODO: Make sure that returned size includes the termination sequence (8 bytes)
  lwz r3, GeckoListSize(BufferPointer)
  branchl r12, HSD_MemAlloc
  mr REG_GeckoBuffer, r3
  stw REG_GeckoBuffer, PDB_DYNAMIC_GECKO_ADDR(REG_DirectoryBuffer)

# Step 2: Ask dolphin for the code list
  li r3, CMD_GET_GECKO_CODES
  stb r3, 0(REG_GeckoBuffer)

  # Request codes
  mr r3, REG_GeckoBuffer
  li r4, 1
  li r5, CONST_ExiWrite
  branchl r12, FN_EXITransferBuffer

# Step 3: Copy code list into our buffer
  mr r3, REG_GeckoBuffer
  lwz r4, GeckoListSize(BufferPointer)
  li r5, CONST_ExiRead
  branchl r12, FN_EXITransferBuffer

# Step 4: Run through code list once to figure out how much space we need
# to allocate for restoration data
  # initialize the backup size to zero
  li r4, 4 # Start with size 4 to fit null pointer to terminate restore
  stw r4, PDB_RESTORE_BUF_SIZE(REG_DirectoryBuffer)

  mr r3, REG_GeckoBuffer # Gecko code list start
  bl Callback_CalculateSize
  mflr r4 # Callback function to calculate size. Will update PDB_RESTORE_BUF_SIZE
  branchl r12, FN_ProcessGecko

# Step 5: Use size returned to allocate a buffer to store the recovery data
  lwz r3, PDB_RESTORE_BUF_SIZE(REG_DirectoryBuffer)
  branchl r12, HSD_MemAlloc
  stw r3, PDB_RESTORE_BUF_ADDR(REG_DirectoryBuffer)
  stw r3, PDB_RESTORE_BUF_WRITE_POS(REG_DirectoryBuffer) # Init pos to start

# Step 6: Iterate through codes again, this time using a callback that will
# apply all of the changes and store the replacements in the restore buffer
  mr r3, REG_GeckoBuffer # Gecko code list start
  bl Callback_ProcessGeckoCode # Callback function to process codes
  mflr r4
  branchl r12, FN_ProcessGecko

  b GECKO_CLEANUP

Callback_CalculateSize:
blrl
  # r5 is input to this function, it contains the size of the replaced data
  cmpwi r5, 0 # If size is 0, either we don't support this codetype or theres nothing to replace
  beq Callback_CalculateSize_End

  lwz r6, primaryDataBuffer(r13)
  lwz r3, PDB_RESTORE_BUF_SIZE(r6)
  addi r3, r3, 8 # For each new code, we need a target address and length
  add r3, r3, r5 # Add size of the replacement to the total length
  stw r3, PDB_RESTORE_BUF_SIZE(r6)

Callback_CalculateSize_End:
  blr

Callback_ProcessGeckoCode:
blrl

.set REG_CodeAddress, 30
.set REG_TargetDataPtr, 29
.set REG_SourceDataPtr, 28
.set REG_ReplaceSize, 27

.set REG_DirectoryBuffer2, 26
.set REG_RestoreBufPos, 25

  # r5 is input to this function, it contains the size of the replaced data
  cmpwi r5, 0 # If size is 0, either we don't support this codetype or theres nothing to replace
  beq Callback_ProcessGeckoCode_End

  backup # TODO: Consider being more efficient about backup and restore?

  mr REG_CodeAddress, r4
  mr REG_ReplaceSize, r5

  lwz r5, 0(REG_CodeAddress)
  rlwinm r5, r5, 0, 0x01FFFFFF
  oris REG_TargetDataPtr, r5, 0x8000 # Injection Address

  lwz REG_DirectoryBuffer2, primaryDataBuffer(r13)
  lwz REG_RestoreBufPos, PDB_RESTORE_BUF_WRITE_POS(REG_DirectoryBuffer2)

  # r3 contains the codetype, do a switch statement on it to prepare for memcpys
  cmpwi r3, 0x04
  beq HANDLE_04

  cmpwi r3, 0x06
  beq HANDLE_06

  cmpwi r3, 0xC2
  beq HANDLE_C2

  # TODO: Assert? It should not be possible to get here. Obviously we could skip
  # TODO: one of the above compares but I'd rather do an assert or something
  # TODO: here to make sure that we haven't made a code error

HANDLE_04:
  addi REG_SourceDataPtr, REG_CodeAddress, 4
  b BACKUP_REPLACED

HANDLE_06:
  addi REG_SourceDataPtr, REG_CodeAddress, 8
  b BACKUP_REPLACED

HANDLE_C2:
  # C2 Step 1: Copy the branch instruction that will overwrite data to buffer.
  # This is done in this way to allow us to back up the data before overwriting it
  addi r4, REG_CodeAddress, 0x8
  sub r3, r4, REG_TargetDataPtr
  rlwinm r3, r3, 0, 6, 29
  oris r3, r3, 0x4800
  stw r3, PDB_RESTORE_C2_BRANCH(REG_DirectoryBuffer2)
  addi REG_SourceDataPtr, REG_DirectoryBuffer2, PDB_RESTORE_C2_BRANCH

  # C2 Step 2: Replace branch instruction in gecko code to return to correct loc
  lwz r3, 0x4(REG_CodeAddress)
  mulli r3, r3, 0x8
  add r4, r3, REG_CodeAddress            # get branch back site
  addi r3, REG_TargetDataPtr, 0x4        # get branch back destination
  sub r3, r3, r4
  rlwinm r3, r3, 0, 6, 29                # extract bits for offset
  oris r3, r3, 0x4800                    # Create branch instruction from it
  subi r3, r3, 0x4                       # subtract 4 i guess
  stw r3, 0x4(r4)                        # place branch instruction

BACKUP_REPLACED:

  # Step 1: Back up the data about to be replaced
  stw REG_TargetDataPtr, 0(REG_RestoreBufPos)
  stw REG_ReplaceSize, 4(REG_RestoreBufPos)

  addi r3, REG_RestoreBufPos, 8 # destination
  mr r4, REG_TargetDataPtr # source
  mr r5, REG_ReplaceSize
  branchl r12, memcpy

  # Increment RestoreBufPos
  addi REG_RestoreBufPos, REG_RestoreBufPos, 8
  add REG_RestoreBufPos, REG_RestoreBufPos, REG_ReplaceSize
  stw REG_RestoreBufPos, PDB_RESTORE_BUF_WRITE_POS(REG_DirectoryBuffer2)

  # Step 2: Replace data
  mr r3, REG_TargetDataPtr # destination
  mr r4, REG_SourceDataPtr # source
  mr r5, REG_ReplaceSize
  branchl r12, memcpy

  mr r3, REG_TargetDataPtr
  mr r4, REG_ReplaceSize
  branchl r12, TRK_flush_cache

  restore

Callback_ProcessGeckoCode_End:
  blr

GECKO_CLEANUP:
  # Cleanup Step 1: Write null ptr to the end of cleanup
  li r3, 0
  lwz r4, PDB_RESTORE_BUF_WRITE_POS(REG_DirectoryBuffer)
  stw r3, 0(r4)

  # Cleanup Step 2: Flush instruction cache for entire gecko code region
  mr r3, REG_GeckoBuffer
  lwz r4, GeckoListSize(BufferPointer)
  branchl r12, TRK_flush_cache

# run macro to create the RestoreInitialRNG process
  Macro_RestoreInitialRNG

Injection_Exit:
restore
lis r3, 0x8017 #execute replaced code line
