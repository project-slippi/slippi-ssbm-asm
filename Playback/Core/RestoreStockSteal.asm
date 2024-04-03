################################################################################
# Address: 8016b9c0
################################################################################

################################################################################
#                      Inject at address 8016b9c0
# Function is StockStealCheck and we're replacing the start button check with
# a request to slippi. Runs when a player is in-game + has no stocks
################################################################################
.include "Common/Common.s"
.include "Playback/Playback.s"

# Setup buffer
  lwz r5,playbackDataBuffer(r13)
  lwz r5,PDB_SECONDARY_EXI_BUF_ADDR(r5)    #Get secondary DMA buffer alloc
  li  r4,CMD_IS_STOCK_STEAL
  stb r4,0x0(r5)        #Store stock steal cmd ID
  lwz r4,frameIndex(r13)   #Get custom match timer
  stw r4,0x1(r5)
  stb r3,0x5(r5)        #Store player port (was in r3 from the start of the injection)
# Transfer buffer over DMA
  mr  r3,r5             #Buffer Pointer
  li  r4,0x6            #Buffer Length
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
# Receive buffer over DMA
  lwz r3,playbackDataBuffer(r13)
  lwz r3,PDB_SECONDARY_EXI_BUF_ADDR(r3)    #Get secondary DMA buffer alloc
  li  r4,0x1
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer

# Check if this player requested a stock steal on this frame
  lwz r3,playbackDataBuffer(r13)
  lwz r3,PDB_SECONDARY_EXI_BUF_ADDR(r3)    #Get secondary DMA buffer alloc
  lbz r3,0x0(r3)
  cmpwi r3,0x0
  beq NoStockSteal
StockSteal:
  branch r12,0x8016ba1c   #branch to respawn code

NoStockSteal:
  branch r12,0x8016bac8   #branch to incrementing the player loop
