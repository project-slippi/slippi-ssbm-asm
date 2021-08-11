################################################################################
# Address: 0x801d24fc
################################################################################

# This code causes the result of the instruction at 801d24fc (PokemonStadium_CheckIfPlayerIsDamaged)
# to be ignored. I think the function may be incorrectly named. It seems to return true false when
# a player is offscreen and I didn't notice it doing anything with player damage. When it returns
# false it causes a screen transition from the "zoomed in" player view to the "zoomed out" view
# (8 -> 7). The problem is that it interacts with the widescreen code in such a way that the
# jumbotron no longer behaves the same. Normally this wouldn't be a problem except for the fact
# that the jumbotron screen changes functions run Rand functions, changing the rng seed. This can
# then cause desyncs between widescreen and non-widescreen.
#
# This code effectively makes it so the zoomed in view is only active for a single frame... Avoiding
# the problematic function call and causing the jumbotrons to behave the same across the board.
# There's probably a better fix but this one worked on the two PS desync replays I had.
nop