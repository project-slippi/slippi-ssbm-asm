################################################################################
# Address: FN_GetTeamCostumeIndex
################################################################################
# Inputs:
# r3: Team IDX
# r4: Internal Char ID (fighter ext id)
################################################################################
# Returns
# r3: Costume Index
################################################################################
# Description:
# Returns Proper Costume Index for a give custom team index and char
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_TEAM_IDX, 31
.set REG_EXTERNAL_CHAR_ID, REG_TEAM_IDX-1

backup
mr REG_TEAM_IDX, r3
mr REG_EXTERNAL_CHAR_ID, r4

mr r3, REG_EXTERNAL_CHAR_ID
cmpwi REG_TEAM_IDX, 3
beq GET_TEAM_COSTUME_IDX_GREEN
cmpwi REG_TEAM_IDX, 2
beq GET_TEAM_COSTUME_IDX_BLUE
cmpwi REG_TEAM_IDX, 1
beq GET_TEAM_COSTUME_IDX_RED

GET_TEAM_COSTUME_IDX_BLUE:
branchl r12, 0x801692bc # CSS_GetCharBlueCostumeIndex
b EXIT
GET_TEAM_COSTUME_IDX_GREEN:
branchl r12, 0x80169290 # CSS_GetCharGreenCostumeIndex
b EXIT
GET_TEAM_COSTUME_IDX_RED:
branchl r12, 0x80169264 # CSS_GetCharRedCostumeIndex

EXIT:
restore
blr