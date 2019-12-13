################################################################################
# Address: 80376a88
################################################################################

# Credit to tauKhan
# From tauKhan:
# make it so that the renewStatus loads masterIndex instead of its own index
# for the block where it inserts inputs
# thus it'll always put inputs to the slot the next RenewMasterStatus uses
# and will never overwrite older data
lbz r0, 0x1(r31)
