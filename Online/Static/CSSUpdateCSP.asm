################################################################################
# Address: FN_CSSUpdateCSP
################################################################################
# Inputs:
# r3 = player index
# r4 = external ID
# r5 = costume ID
# r6 = isNull
################################################################################
# Description:
# Updates CSS Portrait
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_PlayerID, 31
.set REG_ExternalID, 30
.set REG_CostumeID, 29
.set REG_isNull, 28
backup

mr REG_PlayerID,r3
mr REG_ExternalID,r4
mr REG_CostumeID,r5
mr REG_isNull,r6

# get CSS icon data
branchl r12,FN_GetCSSIconData
mr r5,r3
# get port's icon ID
mulli r3,REG_PlayerID,36   # port index
load r4,0x803f0a48
add r4,r3,r4
lbz	r3, 0x03C2(r4)         # get selected icon
# get icon ID's UI ID
mulli	r3, r3, 28
add	r4, r3, r5
lbz	REG_ExternalID, 0x00DC (r4) # UI char id

# Calculate Costume ID from costume Index
mulli	r5, REG_CostumeID, 30
add	r4, REG_ExternalID, r5
#
mr r3,REG_PlayerID
mr r5,REG_isNull
branchl r12, 0x8025D5AC # CSS_UpdateCharCostume?

EXIT:
restore
blr
