################################################################################
# Address: 0x80081388
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"
.include "./LedgeGrab.s"

# whenever cliffcatch action is called
# we record it in a 32-bit flag field, indexed by player GObj
# and skip the action for now, so that it can be called later on.
# -- if a GObj is 32nd or higher in the chain, it is not delayed or recorded.
.set open, 0

# r30 == r3
# r3 must be maintained if returning to function

computeBranchTargetAddress r6, INJ_CheckLastGObj
addi r6, r6, 0x8
mr r3, r30
# r3 = unchanged
# r6 = variables base address

lwz r0, xGate(r6)
lwz r7, xEnabled(r6)
cmpwi cr0, r0, open
cmpwi cr1, r7, 0
cror eq, eq, eq+4
beq- _default
# if gate is open, allow call to go through
# otherwise, prevent the call and save it for later as an indexed bool

# We also treat the code being disabled like having the gate always open.
# this will cause the bools to be blank at te end of collision measurements,
# so it will prevent the code from having any effect.

addi r7, r6, xGetPlayerGObjID
mtctr r7
bctrl
# r3 = unchanged
# r5 = player ID
# r6 = unchanged

cmpwi r5, 32
bge- _default
# also, don't bother with GObjs that we can't keep track of (32-bit field)
# if for some reason there are that many players, then they won't be affected by the gate logic

  # r5 = player ID
  # r6 = variables base address

  li  r4, 1
  slw r5, r4, r5
  lwz r0, 0x4(r6)
  or  r5, r5, r0
  stw r5, 0x4(r6)
  # update flagfield to include this ID

  _skip:
  branch r12, 0x800814ec
  # /if skipping function, return to its epilog
  # /else, default returns execution to prolog

_default:
lwz    r3, 0x002C (r3)