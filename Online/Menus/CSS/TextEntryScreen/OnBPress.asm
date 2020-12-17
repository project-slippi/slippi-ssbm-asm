################################################################################
# Address: 0x8023cdb4 # This code only runs when there's text at the cursor. 
################################################################################

.include "Common/Common.s"

# If the cursor is at the last index, we remove the text but don't move the cursor.
cmpwi r0, r5, 7
bge LAST_INDEX 

branchl r12, 0x8023cdbc # Move the cursor back one place. 
b EXIT

LAST_INDEX:
branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName

EXIT: