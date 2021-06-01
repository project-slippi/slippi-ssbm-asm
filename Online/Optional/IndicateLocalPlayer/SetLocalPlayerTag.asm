################################################################################
# Address: 0x802fd1ec
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

b CODE_START

TAG_BLRL:
blrl
# Nametag (YOU)
.long 0x8278826e
.long 0x82740000

CODE_START:
# r3 is currently set to nametag offset, check if 120 (no name tag)
cmplwi r3, 120
bne RUN_ORIGINAL

# Here we have no nametag set, so let's set r3 to the YOU nametag above
bl TAG_BLRL
mflr r3
b EXIT

RUN_ORIGINAL:
# Here we have a nametag set, so let's use that
branchl r12, 0x8023754c # Nametag_LoadNametagSlotText

EXIT: