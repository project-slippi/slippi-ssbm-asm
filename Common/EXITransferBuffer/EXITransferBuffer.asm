################################################################################
# Address: FN_EXITransferBuffer # 0x800055f0 from Common.s
################################################################################

################################################################################
# Function: ExiTransferBuffer
# Inject @ 800055f0
# ------------------------------------------------------------------------------
# Description: Sets up EXI slot, writes / reads buffer via DMA, closes EXI slot
# ------------------------------------------------------------------------------
# In:  r3 = pointer to buffer
#      r4 = buffer length
#      r5 = read (0x0) or write (0x1)
#
# Out: r3 = transfer status (1 = success, -1 = EXIAttach failed, 
#                            -2 = EXILock failed, -3 = EXISelect failed, 
#                            -4 = EXIDma failed, -5 = EXISync failed)
################################################################################
.include "Common/Common.s"

# Register names
.set REG_TransferBehavior, 31
.set REG_BufferPointer, 30
.set REG_BufferLength, 29
.set REG_InterruptIdx, 28
.set REG_AlignedLength, 27
.set REG_EXIStatus, 26

ExiTransferBuffer:
# Store stack frame
  backup

# Backup buffer pointer
  mr REG_BufferPointer,r3
# Backup buffer length
  mr REG_BufferLength,r4
# Backup EXI transfer behavior
  mr REG_TransferBehavior,r5

# Calculate aligned boundary for transfer buffer. Required for hardware EXI DMA transfer
  byteAlign32 REG_AlignedLength, REG_BufferLength

# Disable interrupts. I think perhaps we can have EXI transfer issues when
# this process is interrupted?
  branchl r12, OSDisableInterrupts
  mr REG_InterruptIdx, r3

# Init EXI status, used to determine if the transfer was successful and in
# the the event of a failure, why the transfer failed.
  li REG_EXIStatus, 1

  cmpwi REG_TransferBehavior,CONST_ExiRead
  beq FLUSH_WRITE_LOOP_END # Only flush before write when writing

# First we write 0x00 to the bytes following all the messages up to the 32 byte boundary. This will
# be used as a "nop" command, for which the receiver can skip to next byte. This needs to be done
# because on hardware, DMA sends must be sent as 32 byte chunks. Currently I think allocated buffers
# should always reserve a size up to the 32 byte boundary so this should be safe as long as the
# addressed passed in is of a buffer allocated with HSD_MemAlloc
  add r3, REG_BufferPointer, REG_BufferLength
  sub r4, REG_AlignedLength, REG_BufferLength
  branchl r12, Zero_AreaLength

  # Start flush loop to write the data in buf through to RAM.
  # Cache blocks are 32 bytes in length and the buffer obtained from malloc
  # should be guaranteed to be aligned at the start of a cache block.
  li r3, 0
FLUSH_WRITE_LOOP:
  dcbf REG_BufferPointer, r3
  addi r3, r3, 32
  cmpw r3, REG_BufferLength
  blt+ FLUSH_WRITE_LOOP
  sync
  isync
FLUSH_WRITE_LOOP_END:

InitializeEXI:
# Step 1 - Prepare slot
# Prepare to call EXIAttach (803464c0)
  li r3, STG_EXIIndex # slot
  li r4, 0 # maybe a callback? leave 0
  branchl r12, EXIAttach
  cmpwi r3,1
  beq ExiInit_Lock
  li REG_EXIStatus, -1
  b Exit
ExiInit_Lock:
# Prepare to call EXILock (80346d80) r3: 0
  li r3, STG_EXIIndex # slot
  li r4, 0 # unk, copied from OSInitSRAM
  li r5, 1 # unk, copied from OSInitSRAM
  branchl r12, EXILock
  cmpwi r3,1
  beq ExiInit_Select
  li REG_EXIStatus, -2
  b ExiCleanup_Detatch
ExiInit_Select:
# Prepare to call EXISelect (80346688) r3: 0, r4: 0, r5: 4
  li r3, STG_EXIIndex # slot
  li r4, 0 # device
  li r5, 5 # freq
  branchl r12, EXISelect
  cmpwi r3,1
  beq ExiInit_Dma
  li REG_EXIStatus, -3
  b ExiCleanup_Unlock 

ExiInit_Dma:
# Step 2 - Write

# Prepare to call EXIDma (80345e60)
  li r3, STG_EXIIndex # slot
  mr r4, REG_BufferPointer    #buffer location
  mr r5, REG_AlignedLength     #length
  mr r6, REG_TransferBehavior # write mode input. 1 is write
  li r7, 0                # r7 is a callback address. Dunno what to use so just set to 0
  branchl r12, EXIDma
  cmpwi r3,1
  beq ExiInit_Sync
  li REG_EXIStatus, -4
  b ExiCleanup_Deselect
ExiInit_Sync:
# Prepare to call EXISync (80345f4c)
  li r3, STG_EXIIndex # slot
  branchl r12, EXISync
  cmpwi r3,1
  beq ExiCleanup_Deselect
  li REG_EXIStatus, -5
  b ExiCleanup_Deselect

ExiCleanup_Deselect:
# Step 3 - Close slot
# Prepare to call EXIDeselect (803467b4)
  li r3, STG_EXIIndex # Load input param for slot
  branchl r12, EXIDeselect

ExiCleanup_Unlock:
# Prepare to call EXIUnlock (80346e74)
  li r3, STG_EXIIndex # Load input param for slot
  branchl r12, EXIUnlock

ExiCleanup_Detatch:
# Prepare to call EXIDetach (803465cc) r3: 0
  li r3, STG_EXIIndex # Load input param for slot
  branchl r12, EXIDetach

ExiCleanup_InvalidateCheck:
  cmpwi REG_TransferBehavior,CONST_ExiRead
  bne INVALIDATE_READ_LOOP_END # Only invalidate cache when doing a read

  # Invalidate cache for the values we just read from EXI. This was actually
  # broken forever and stuff still worked so it might not be needed
  li r3, 0
INVALIDATE_READ_LOOP:
  dcbi REG_BufferPointer, r3
  addi r3, r3, 32
  cmpw r3, REG_BufferLength
  blt+ INVALIDATE_READ_LOOP
  sync
  isync
INVALIDATE_READ_LOOP_END:

Exit:
  mr r3, REG_InterruptIdx
  branchl r12, OSRestoreInterrupts

#restore registers and sp
  mr r3, REG_EXIStatus
  restore
  blr
