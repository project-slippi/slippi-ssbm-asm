################################################################################
# Address: 0x80260e14 # CSS_CursorHighlightUpdateCSPInfo... Before invoking
# CSS_CursorHighlightUpdateCSPInfo
################################################################################

.include "Common/Common.s"
# Just branch to PreventColroResetRandomChar hack since it's exactly the same
# behavior for TEAMS and vanilla game
branch r12, 0x80260b90
