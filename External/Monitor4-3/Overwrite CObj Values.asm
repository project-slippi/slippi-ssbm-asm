################################################################################
# Address: 8036A4A8
################################################################################
.include "../../Common/Common.s"

bl  Floats
mflr r3
lfs f1,0x0(r3) # Originally f1 is loaded to 1.3636

b END

Floats:
blrl
.float 1.3333 # TODO: Strange that this is equal to 4/3... Might be a coincidence and need tweaks?

END:
