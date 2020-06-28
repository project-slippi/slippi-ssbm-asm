################################################################################
# Address: 0x8023e290
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

lbz r12, OFST_R13_NAME_ENTRY_MODE(r13)
cmpwi r12, 0
beq EXIT

# If direct mode, use english settings for initialization
branch r12, 0x8023e29c # Branch to english handler

EXIT:
# Original code line
branchl r12, 0x8000ae90 # LanguageSwitch_LoadCurrent_CompareUS
