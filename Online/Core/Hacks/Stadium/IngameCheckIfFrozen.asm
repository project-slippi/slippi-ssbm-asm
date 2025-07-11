################################################################################
# Address: 0x801d457c # PokemonStadium_TransformationDecide
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

CODE_START:

  # original code will either branch to the end of the function or resume as normal
  lbz r3, FSToggle(rtoc)

EXIT:
