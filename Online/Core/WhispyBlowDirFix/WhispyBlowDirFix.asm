################################################################################
# Address: 8008653c
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"

# This was added to prevent a bug where if a fighter is camera KO'd on the same frames that
# whispy decides what direction to blow, whispy would check the fighter bones at 80086538
# to determine if the character is to the left or right of center. During a fast-forward/rollback,
# however, the bone positions can be wrong. This is likely due to our FreezeDeadUpFallPhysics logic?
# Could be worth taking a look at that some time to see if we can make it behave identically during
# a fast-forward. I'm not super confident though because I think it's dependent on camera position
# which I don't think updates correctly all the time during a FFW?

lwz r12, 0x2C(r29)
lwz r3, 0x10(r12)
cmpwi r3, 0xB
bgt EXIT

# If character is in a Dead animation (such as camera KO), we load zero into r0 in order
# to effectively say that the character is on neither side (left or right), skipping the
# character in the logic calculation.
li r0, 0
branch r12, 0x8008655c

EXIT:
lfs f1, 0x0020(sp)