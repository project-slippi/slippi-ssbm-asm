# Inject at 801a4d7c
.include "../Common/Common.s"

backup

# Setup buffer
  lwz r5,secondaryDmaBuffer(r13)    #Get secondary DMA buffer alloc

  # Function gets called when we load the wait screen and when a game starts.
  # The first time the wait screen loads we haven't prepared our buffer yet.
  # This branch will prevent the game from crashing on load. But the other
  # times we transition back to the Wait screen we seem to be getting back a
  # 0xFF from Dolphin. Is our buffer free'd by then? I worry we might be
  # writting to risky memory
  cmpwi r5, 0
  beq Exit

  li  r4,CONST_SlippiCmdGetBufferedFrameCount
  stb r4,0x0(r5)        #Store frame count cmd ID
# Transfer buffer over DMA
  mr  r3,r5             #Buffer Pointer
  li  r4,0x1            #Buffer Length
  li  r5,CONST_ExiWrite
  branchl r12,FN_EXITransferBuffer
# Receive buffer over DMA
  lwz r3,secondaryDmaBuffer(r13)    #Get secondary DMA buffer alloc
  li  r4,0x1
  li  r5,CONST_ExiRead
  branchl r12,FN_EXITransferBuffer

# Get back result
  lwz r3,secondaryDmaBuffer(r13)    #Get secondary DMA buffer alloc
  lbz r4,0x0(r3) # Load a byte describing number of frames to skip

# 0x804C1F7B byte contains number of inputs polled in queue
  lis r3, 0x804C
  stb r4, 0x1f7b(r3)

Exit:
restore
lis r3, 0x8047 # replaced code line
