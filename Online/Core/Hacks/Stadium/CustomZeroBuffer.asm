################################################################################
# Address: 0x801c65c8
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"

.set REG_DATA, 31
.set HSD_FreeToHeap, 0x80015CA8

CODE_START:
  mr. REG_DATA, r3
  beq EXIT

  lwz r4, 0(REG_DATA) 
  addis	r0, r4, 1
  cmplwi r0, 65535 # if the file size is not -1
  beq ZERO_MEM

  # check if this area has been zeroed already. if it was, this was probably a rollback
  lwz r0, 0(REG_DATA)
  lwz r3, 4(REG_DATA)
  or r3, r0, r3
  lwz r0, 8(REG_DATA)
  or. r3, r0, r3
  beq EXIT

  # when we reach here, it means we are probably freeing the transformation file back to the heap
  lwz r3, 8(REG_DATA)
  cmplwi r3, 1
  bne ZERO_MEM

  li r3, 0
  lwz r4, 0(REG_DATA)
  branchl r12, HSD_FreeToHeap

  ZERO_MEM:
    mr r3, REG_DATA
    li r4, 12
    branchl r12, Zero_AreaLength

EXIT:
  branch r12, 0x801c660c # end of function
