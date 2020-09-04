################################################################################
# Address: 0x8023cde4 # Jump to 'OnEnterText.asm'
################################################################################

.include "Common/Common.s"
# Don't autocopmlete if we've removed all text.
cmpwi r0, r5, 1
beq EXIT
branchl r12, 0x8023c730 # Load autocomplete suggestion for text.
EXIT:
branchl r12, 0x8023ce4c # NameEntry_UpdateTypedName
