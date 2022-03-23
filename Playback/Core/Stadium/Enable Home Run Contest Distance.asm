################################################################################
# Address: 0x8016e8c8
################################################################################
  .include "Common/Common.s"

  # Load the current stage id from the static match block
  load r12, 0x8046db77
  lbz r12, 0 (r12)

  # Compare with the id for the Home Run Contest 
  cmpwi r12, 0x54
  beq LOAD_HRC_DISTANCE

  # Original instruction
  lwz r12, 0x0044 (r31)
  b EXIT

LOAD_HRC_DISTANCE:
  # Load the HRC Distance Display
  load r12, 0x80181998

EXIT:
