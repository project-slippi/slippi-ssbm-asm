################################################################################
# Address: 8016e74c
################################################################################

################################################################################
#                      Inject at address 8016e74c
# Function is StartMelee and we are loading game information right before
# it gets read to initialize the match
################################################################################
.include "Common/Common.s"
.include "PlaybackConsole/Playback.s"

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
  li  r3,128
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

READ_DATA:
  lwz r3,InfoRNGSeed(BufferPointer)
  lis r4, 0x804D
  stw r3, 0x5F90(r4) #store random seed

  # clogf "RNG Seed: %08X\n", "mr r5, 3"

Injection_Exit:
restore
lis r3, 0x8017 #execute replaced code line
