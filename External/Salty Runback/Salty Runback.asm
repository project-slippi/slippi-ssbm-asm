#To be inserted at 801a5b14
.include "../../Common/Common.s"

#Get all players inputs
  li  r3,4
  branchl r12,0x801a3680

#Check Inputs
  rlwinm. r0, r4, 0, 23, 23 #check A
  beq- LoadCSS
  rlwinm. r0, r4, 0, 22, 22 #check B
  bne- Runback
  b LoadCSS

Runback:
  li r27,0x2 #reload match scene
  b exit

LoadCSS:
  li r27,0x0  #load CSS

exit:
Original:
  li	r29, 0
