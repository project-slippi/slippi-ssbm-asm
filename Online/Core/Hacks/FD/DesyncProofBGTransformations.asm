################################################################################
# Address: 0x8021aae4
# Tags: [affects-gameplay]
################################################################################
# This replaces the call to FinalDestination_BGTransformThink to wrap it
# in logic that stores and restores the RNG seed, ensuring consistent RNG
# behavior whether someone freezes or unfreezes the transformations.
################################################################################

.include "Common/Common.s"

# After doing more research, it seems that this function runs after
# PlayerThink_Interrupt but before PlayerThink_Physics. That means that most
# RNG things we care about such as Peach's turnip pulls, GnW's hammer, etc
# have already been computed and desync'ing RNG here might not actually matter

# We can use r31 here because it's backed up and restored by the parent function. 
# We just need to make sure we manage it intelligently because the parent function
# needs it when we exit
.set REG_SEED, 31

# Load RNG seed into r31
lis r3, 0x804D
lwz REG_SEED, 0x5F90(r3)

# Call replaced function
mr r3, r30
branchl r12, 0x8021b2e8 # FinalDestination_BGTransformThink

# Restore RNG seed from r31
lis r3, 0x804D
stw REG_SEED, 0x5F90(r3)

# Restore r31 to it's parent function value
lwz REG_SEED, 0x2C(r30)