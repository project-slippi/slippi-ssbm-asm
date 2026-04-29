################################################################################
# Address: FN_OnlineStaticDataBlrl
################################################################################
# Description:
# Can be called with bl in order to receive pointer to static data. Data
# can be added in here to avoid polluting and creating static data in smaller
# files
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

blrl
createOnlineStaticDataBlock