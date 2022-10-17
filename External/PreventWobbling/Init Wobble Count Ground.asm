################################################################################
# Address: 800DC388
################################################################################
.include "Common/Common.s"

.set  REG_DefenderData,29

.set  OFST_WobbleCounter,0x2350
.set  OFST_LastMoveID,0x2352

#Init count
  li  r3,0
  stb r3,OFST_WobbleCounter(REG_DefenderData)
#Init last move ID
  li  r3,-1
  sth r3,OFST_LastMoveID(REG_DefenderData)
  
#Original codeline
  lwz	r0, 0x005C (sp)
