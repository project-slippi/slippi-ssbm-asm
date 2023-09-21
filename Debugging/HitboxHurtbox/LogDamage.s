################################################################################
# Address: 0x8008e258
################################################################################

.include "Common/Common.s"

lfs	f1, 0x186C(r29) # Damage?
fmr f2, f30 # Damage. TODO: Truncate/Cast?
fmr f3, f28
fmr f4, f29
logf LOG_LEVEL_NOTICE, "Damage details. Damage: %f, Stun: %f, KB: %f, Angle: %f, Direction: ?"

mr r5, r31
logf LOG_LEVEL_NOTICE, "Damage animation: 0x%X"

# Replaced codeline
mr r3, r24