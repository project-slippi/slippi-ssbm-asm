################################################################################
# Address: PALToggleAddr
################################################################################
.include "Common/Common.s"

# This is picked up by SendGameInfo to store whether
# pre-loading is enabled. This bool is mostly deprecated
# due to dynamic code application but is still here so that
# the data is correct in the file
.long 0x01000000
