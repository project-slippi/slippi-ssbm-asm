################################################################################
# Address: FN_CheckAltStageName
################################################################################
# Inputs:
# r3 = text ptr
# r4 = ext stage id
################################################################################
# Description:
# Checks to run alternate stage name logic (non-applicable to vanilla melee)
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

EXIT:
li r3,0
blr
