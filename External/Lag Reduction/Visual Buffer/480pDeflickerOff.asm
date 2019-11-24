################################################################################
# Address: 801a4570
#################################################################################
.include "Common/Common.s"

.set  VIStruct,0x8046b0f0
.set  ScreenDisplay_Adjust,0x8015f588

#Enable 480p
	load	r3,VIStruct
	li	r4,1
	stw	r4,0x8(r3)
#Call VIConfigure
	li	r3,0	#disables deflicker and will enable 480p
	branchl	r12,ScreenDisplay_Adjust

Injection_Exit:
  li  r3,0
