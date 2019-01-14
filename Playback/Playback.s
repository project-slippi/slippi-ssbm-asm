################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us). These must not interfere with the Functions
# in Common/Common.s
.set FN_FetchGameFrame,0x800055f4

################################################################################
# Const Definitions
################################################################################
.set CONST_FrameFetchResult_Wait, 0
.set CONST_FrameFetchResult_Continue, 1
.set CONST_FrameFetchResult_Terminate, 2
