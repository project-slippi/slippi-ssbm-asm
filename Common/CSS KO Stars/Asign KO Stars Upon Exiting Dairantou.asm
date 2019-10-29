################################################################################
# Address: 8016ebac
################################################################################
.include "Common/Common.s"

#Check if VS Mode
  load r3,0x80479D30
  lbz r3,0(r3)
  cmpwi r3,0x02
  bne Exit

#Init Struct?
  load	r3,0x803dda00		#Get Some Scene Struct
  branchl	r12,0x801a5f00		#Wipe and Copy Match Info

#Update KO Star Count
  load	r3,0x803dda00		#Get Some Scene Struct
  lwz	r4, -0x77C0 (r13) #Get SSS Struct
  addi	r4, r4, 1424
  li  r5,1
  branchl	r12,0x801a5f64		#Update KO Stars

Exit:
  lwz	r0, 0x001C (sp)
  lwz	r31, 0x0014 (sp)
