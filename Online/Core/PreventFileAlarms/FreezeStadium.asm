################################################################################
# Address: 0x801d457c # PokemonStadium_TransformationDecide
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_DATA, 31

b CODE_START

DATA_BLRL:
blrl
.set IS_FROZEN, 0
.byte 0
.align 2

CODE_START:
  backup

  bl DATA_BLRL
  mflr REG_DATA

  # original code will either branch to the end of the function or resume as normal
  lbz r3, IS_FROZEN(REG_DATA)

EXIT:
  restore
