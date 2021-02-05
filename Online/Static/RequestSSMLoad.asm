################################################################################
# Address: FN_RequestSSM
################################################################################
# Inputs:
# r3 = ssm Index
################################################################################
# Description:
# Queues SSM to load
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set  REG_SSMID,3
.set  REG_ToLoadOrig,12

#Check if null ssm ID
  cmpwi  REG_SSMID,55
  beq Exit

#Get Disposable Orig
  load REG_ToLoadOrig,0x804337c4
#Queue up ssm load
  li  r4,1
  mulli REG_SSMID,REG_SSMID,4
  stwx  r4,REG_SSMID,REG_ToLoadOrig

Exit:
  blr
