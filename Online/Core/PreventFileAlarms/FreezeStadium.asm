################################################################################
# Address: 0x801d4578 # PokemonStadium_TransformationDecide
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

fmr f31, f1 # Original code line

# Skip transformation logic
branch r12, 0x801d4fd8
