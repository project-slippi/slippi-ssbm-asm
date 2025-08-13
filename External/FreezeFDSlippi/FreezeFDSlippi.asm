################################################################################
# Address: 0x8021aae0
################################################################################
# This is a slightly different freeze implementation so that the RNG protection
# unfrozen FD code can have its own injection.
################################################################################

# Technically without DesyncProofBGTransformations.asm active, I think this code
# might affect gameplay. See that file for the reasons. That said I don't really
# want to mark it as affects gameplay so that watching the replay allows for
# all the FD BG transformations. Also I think we will only have this code
# active when the code mentioned above is active, in which case affects-gameplay
# is not true.

# TODO: Maybe add an affects-gameplay dependency tag or something? Idk

b 0x8