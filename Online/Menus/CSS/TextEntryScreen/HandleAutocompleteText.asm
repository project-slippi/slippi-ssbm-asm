################################################################################
# Address: 0x8023cf90 
################################################################################

.include "Common/Common.s"

b CODE_START

 DATA_BLRL:
 blrl 
 .set DEFAULT_COLOR, 0
 .long 0x00000000
 .set AUTOCOMPLETE_COLOR, DEFAULT_COLOR + 4
 .long 0x8E9196FF
 .align 2

CODE_START:

.set REG_DATA_ADDR, 18
.set ACL, 19

 bl DATA_BLRL
 mflr REG_DATA_ADDR

addi r29, REG_DATA_ADDR, DEFAULT_COLOR 
cmpw ACL, r4
bgt EXIT
addi r29, REG_DATA_ADDR, AUTOCOMPLETE_COLOR

EXIT:
mr r5, r29