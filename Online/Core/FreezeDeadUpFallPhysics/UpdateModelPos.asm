################################################################################
# Address: 0x80080e80
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"
.include "Online/Online.s"

/*
The fighter's position is centered with the camera by directly
updating the model's position with respect to the camera's view matrix.

However, it also updates the fighter's physics position. This becomes a
problem when screen shake is disabled on one client, as it will cause
the physics position of the fighter being screen ko'd to differ slightly.
This only seems to matter in the case of Ice Climbers, because Nana uses
Popo's physics position to determine her next action.
*/

backup

# update camera mtx and return mtx ptr?
  branchl r12,0x800310b8
# get inverted viewing mtx ptr
  branchl r12,0x80369808

# mult with position vector
  addi	r4, r30, 0x2350   # position vector
  addi	r5, sp, 0x80    # output to temp vector on stack
  branchl r12,0x80342aa8

# update model position
  lwz r3, 0x80(sp) # vector X
  stw r3, 0x38(31) # model X
  lwz r3, 0x84(sp) # vector Y
  stw r3, 0x3c(31) # model Y
  lwz r3, 0x88(sp) # vector Z
  stw r3, 0x40(31) # model Z

Exit:
  restore
  branch r12,0x80080ee4