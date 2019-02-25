#To be inserted at 80266ce0
.include "../../Common/Common.s"

#######################################
## Runs During CSS -> SSS Transition ##
#######################################

#Get Teams On/Off Bool
  lwz	r3, -0x49F0 (r13)
  lbz	r3,0x18(r3)

#Check If Teams is On or Off
  cmpwi	r3,0x1
  beq	Doubles

Singles:
  li  r3,1
  b Toggle
Doubles:
  li  r3,0
  b Toggle

Toggle:
#Get Random Stage Select Bitflags
  lwz	r5, -0x77C0 (r13)
  addi	r5, r5, 7344
  lwz	r0,0x18(r5)
#Flip FoD Bit On in Random Stage Bitflag (FoD is bit #26)
  rlwimi	r0,r3,5,26,26
  stw	r0,0x18(r5)

/*
#Get Timer Value In Memory
lwz	r3, -0x77C0 (r13)
addi	r3, r3, 6224
#Store 8
li	r4,8		#8 Mins
stb	r4,0x8(r3)		#Store To Memory
*/


Exit:
li	r3, 1
