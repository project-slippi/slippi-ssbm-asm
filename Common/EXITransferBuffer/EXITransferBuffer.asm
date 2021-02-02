################################################################################
# Address: FN_EXITransferBuffer # 0x800055f0 from Common.s
################################################################################

################################################################################
# Function: ExiTransferBuffer
# Inject @ 800055f0
# ------------------------------------------------------------------------------
# Description: Sets up EXI slot, writes / reads buffer via DMA, closes EXI slot
# ------------------------------------------------------------------------------
# In: r3 = pointer to buffer
#     r4 = buffer length
#     r5 = read (0x0) or write (0x1)
################################################################################
.include "Common/Common.s"

# Register names
.set REG_TransferBehavior, 31
.set REG_BufferPointer, 30
.set REG_BufferLength, 29
.set REG_InterruptIdx, 28

ExiTransferBuffer:
# Store stack frame
  backup

# Backup buffer pointer
  mr REG_BufferPointer,r3
# Backup buffer length
  mr REG_BufferLength,r4
# Backup EXI transfer behavior
  mr REG_TransferBehavior,r5

# Disable interrupts. I think perhaps we can have EXI transfer issues when
# this process is interrupted?
  branchl r12, OSDisableInterrupts
  mr REG_InterruptIdx, r3

  cmpwi REG_TransferBehavior,CONST_ExiRead
  beq FLUSH_WRITE_LOOP_END # Only flush before write when writing

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
# Prepare to call EXILock (80346d80) r3: 0
  li r3, STG_EXIIndex # slot
  branchl r12, EXILock
# Prepare to call EXISelect (80346688) r3: 0, r4: 0, r5: 4
  li r3, STG_EXIIndex # slot
  li r4, 0 # device
  li r5, 5 # freq
  branchl r12, EXISelect

# Step 2 - Write
# Prepare to call EXIDma (80345e60)
  li r3, STG_EXIIndex # slot
  mr r4, REG_BufferPointer    #buffer location
  mr r5, REG_BufferLength     #length
  mr r6, REG_TransferBehavior # write mode input. 1 is write
  li r7, 0                # r7 is a callback address. Dunno what to use so just set to 0
  branchl r12, EXIDma
# Prepare to call EXISync (80345f4c)
  li r3, STG_EXIIndex # slot
  branchl r12, EXISync

# Step 3 - Close slot
# Prepare to call EXIDeselect (803467b4)
  li r3, STG_EXIIndex # Load input param for slot
  branchl r12, EXIDeselect

# Prepare to call EXIUnlock (80346e74)
  li r3, STG_EXIIndex # Load input param for slot
  branchl r12, EXIUnlock

# Prepare to call EXIDetach (803465cc) r3: 0
  li r3, STG_EXIIndex # Load input param for slot
  branchl r12, EXIDetach

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
  restore
  blr
