################################################################################
# Address: 0x803A5798 # Replaces Text_AllocateMenuTextMemory
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_SIZE, 23
.set REG_MEM_ADDR, REG_SIZE+1

backup
# r3 holds the size
mr REG_SIZE, r3

mr r3, REG_SIZE
branchl r12, HSD_MemAlloc
mr REG_MEM_ADDR, r3 # save result address into REG_MEM_ADDR

# Zero out
mr r3, REG_MEM_ADDR
mr r4, REG_SIZE
branchl r12, Zero_AreaLength

mr r3, REG_MEM_ADDR # Return Pointer to saved memory
restore

blr
