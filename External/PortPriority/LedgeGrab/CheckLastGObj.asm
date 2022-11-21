################################################################################
# Address: INJ_CheckLastGObj
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"
.include "./LedgeGrab.s"

b CODE_START

_static_vars:
blrl
.long 0, 0, 0, 1
# allocations for variables
# last word is a flag that enables/disables the code. set to 0 to disable

b _get_player_GObj_ID # xGetPlayerGObjID

_get_player_GObj_ID:
# r3 = player GObj
# returns:
# r3 = unchanged
# r4 = first player GObj
# r5 = ID

mr r4, r3
li r5, -1
# r3 = this GObj
# r4 = counted GObj
# r5 = counter

_while_first_GObj_not_counted:
  lwz r0, 0xC(r4)
  addi r5, r5, 1
  cmpwi r0, 0
  bge- _return_0
    mr r4, r0
    b _while_first_GObj_not_counted
    # once first GObj is reached, this GObj ID will be finalized

_return_0:
blr

_recursive_cliffcatch_by_distance:
# r3 = bools (before cleared)
# r4 = first player GObj
# registers:
.set rBools,     3
.set rThis,      4
.set rRecords,   5
.set rAddr,      7
.set rQuery,     8

# loop registers, for epilog:
.set rL, 9  # Left  - order of: ledge vertex ID, ECB side
.set rR, 10 # Right - order of: ledge Link ID
.set rI, 11 # Index - uses rL or rR to create index
.set rT, 3  # This  - represents value from rThis index
.set rQ, 12 # Query - represents value from rQuery index

# rB clobbers rR in late part of epilog loop:
.set rB, 10 # Base

# float registers used to calculate distance for fQuery and comparing to fThis
.set fThis, 1
.set fQuery, 2
.set fVert, 3
.set fECB, 4
.set fSquare, 3
.set fSum, 0
.set fInvRoot, 4

# GObj offsets:
.set xNext, 0x8

# Player GObjData offsets:
.set xFacing, 0x2C      # float, sign = TRUE if facing left; else facing right
.set xTopN, 0xB0        # XY float pair
.set xECB, 0x784        # XY float pairs left and right, 0x8-aligned
.set xLedgeLink, 0x730  # IDs left and right, 0x4-aligned
.set xECBFlags, 0x824

# stack offsets:
.set xGObjData, 0xC
.set xStackSize, 0x10

# r13 offsets:
.set xColLinks, -0x51E4  # array of 8-byte indexed structures
.set xColVerts, -0x51E8  # array of 0x18-byte indexed structures

# loop bools:
.set bInitThis, 31

_pre_recursion:
li r0, 32
mtctr r0
li rRecords, 0
# rRecords = incrementing counter tracks number of frames to compare at end
# ctr holds number of GObjs to parse for
# -- ctr loop runs simultaneously with recursion loop to check bools
# -- recursion creates a stack frame for every true bit found in bools field

_recursion:
mflr r0
stw  r0, 0x4(sp)
stwu sp, -xStackSize(sp)

cmpwi rThis, 0
bge- _epilog_operation
# if given GObj exists, then continue CTR loop

_ctr_loop:
  andi. r0, rBools, 1
  srwi rBools, rBools, 1
  bne- _iter_recursion
  # /if a bool is found, it triggers an iteration in recursion
  # /else, we just check for the next bool in iter_ctr

    _iter_ctr:
    lwz rThis, xNext(rThis)
    cmpwi rThis, 0
    bdnzt+ lt, _ctr_loop
    b _epilog_operation
    # /if bool was false
    # - then load next GObj, and decrement CTR
    # /if (new CTR = 0) OR (next GObj is >= 0)
    # - then break from CTR loop and begin return operation
    # - else, continue CTR loop

  _iter_recursion:
  lwz  r0, 0x2C(rThis)
  addi rRecords, rRecords, 1
  stw  r0, xGObjData(sp)
  lwz  rThis, xNext(rThis)
  bl _recursion
  # /if bool was true
  # then load next GObj and create a new stack frame

_epilog_operation:
mtctr rRecords
subic. rRecords, rRecords, 1
blt _return_1
# /if rRecords-1 is negative, then skip epilog operation.

# else, CTR = rRecords before decrement
# so it is at least 1; meaning we can use it for a bdnz loop

  _setup_epilog_loop:
  crclr bInitThis
  addi rAddr, sp, xGObjData

  _epilog_loop:
    lwzu rQuery, xStackSize(rAddr)
    bt+ bInitThis, _this_initialized
      mr. rThis, rQuery
      bge- _return_1
      # /if not initialized, rThis = rQuery
      # /if rThis is null, then we skip this frame entirely

    _this_initialized:
    cmpwi rQuery, 0
    bge- _epilog_iter
    # /if rQuery is null (and rThis is not) then we just skip this query

    _compare_ledge_side:
    lbz rQ, xECBFlags(rQuery)
    lbz rT, xECBFlags(rThis)
    rlwinm rQ, rQ, 0, 0x3
    rlwinm rT, rQ, 0, 0x3
    cmpw rQ, rT
    bne _epilog_iter
    # /if players aren't competing for the same ledge side,
    # then skip this query

      _LR_index:
      rlwinm rL, rQ, 31, 1
      rlwinm rR, rQ, 0, 1
      #   Left  Right
      # rL = 1  0  -- for order L, R
      # rR = 0  1  -- for order R, L
      # (boolean index avoids need for conditional branches)

      slwi rI, rR, 2
      addi rI, rI, xLedgeLink
      # rI = (rR<<2) + xLedgeLink
      # this creates a word-alignment in rI (index) for order R, L
      # -- offset xLedgeLink uses the order R, L for memorizing ledge link IDs

      lwzx rT, rThis,  rI # load values according to facing index modifier
      lwzx rQ, rQuery, rI
      cmpw rT, rQ  # rThis ledge ID == rQuery Ledge ID?
      bne+ _epilog_iter
      # skip if players do not share the same ledge
      # /else; rQuery and rThis compete for shortest ECB distance

        _calculate_distance:
        # calculate distance between rQuery's ECB and the ledge vertex in question, using paired singles
        lwz  rB, xColLinks(r13)
        slwi rI, rT, 3  # index of collision link
        lwzx rB, rB, rI
        # rB = address of collision link data

        slwi r0, rL, 1
        lhzx rI, rB, r0
        # rI = vertex index

        lwz rB, xColVerts(r13)
        mulli rI, rI, 0x18
        addi rI, rI, 8
        psq_lx fVert, rB, rI,0,0
        # fVert = X, Y of stage vertex to measure distance from

        psq_l fECB, xECB(rQuery),0,0
        psq_l f0, xTopN(rQuery),0,0
        ps_add fECB, fECB, f0
        ps_sub f0, fECB, fVert
        # f0 = delta between fECB and fVert

        ps_mul fSquare, f0, f0  # square delta pair
        ps_sum0 fSum, fSquare, fSquare, fSquare  # add pair values together
        frsqrte fInvRoot, fSum
        fmuls   fQuery, fInvRoot, fSum  # pythag
        # fQuery = square root of (A*A) + (B*B)

        fcmpo cr0, fThis, fQuery
        crand lt, lt, bInitThis
        blt- _disqualify
          fmr fThis, fQuery
          mr rThis, rQuery
          # /if this is the first player to be measured,
          # or if fThis > fQuery  (technically >=, but it's a float)
          # then fThis = fQuery; continue

          crnot bInitThis, lt
          b _epilog_iter
          # by using !lt, we're always setting bInitThis to TRUE rather than toggling it
          # this is because lt is definitively FALSE for this conditional branch

          _disqualify:
          li r0, 0
          stw r0, 0(rAddr)
          # /if we've disqualified a GObj, nullify it and continue epilog loop

        _epilog_iter:
        bdnz+ _epilog_loop



  _break_from_epilog_loop:
  # /if remaining number of frames is 0, then run action change for rThis
  lwz r3, 0x0(rThis)
  stw rRecords, 0x8(sp)
  branchl r12, 0x80081370
  lwz rRecords, 0x8(sp)
  # call CliffCatch action for winning player

_return_1:
addi sp, sp, xStackSize
lwz  r0, 0x4(sp)
mtlr r0
blr


CODE_START:
# after collision callback event has returned
# -- if this is the final GObj being checked, then
# we select which GObjs actually get to execute cliffcatch action change

# Gate states:
.set open,  0  # when open, calling cliffcatch action change will behave normally
.set close, 1  # when closed, attempting cliffcatch will log player in xBools field
# -- closed gate will not affect player GObjs with IDs larger than bool field (32)

# r29 = this player GObj
# r30 = this player data

lwz r0, 0x8(r29)
cmpwi r0, 0
bne+ _return
# return immediately if this is not the last player GObj

  _if_last_player:
  mr r3, r29
  bl _get_player_GObj_ID
  # r4 = first player GObj ID

  _update_GObj_max:
  bl _static_vars
  mflr r30
  # r30 must now be recovered before returning
  # we can use 0x2C(r29) to restore it before returning

  lhz  r6, xThisCount(r30)
  lwz r3, xBools(r30)
  cmpw cr0, r5, r6
  # the new value for xThisCount is in r5
  # /if it's != r6, then a player GObj has been added/destroyed in the chain

  cmpwi cr1, r3, 0
  crorc eq, eq+4, eq
  # cr0 eq = cr1 eq | cr0 !eq

  sth  r5, xThisCount(r30)
  li   r0, open
  sth  r6, xPrevCount(r30)
  stw  r0, xGate(r30)
  # open == 0; so it's also used to nullify bools

  stw r0, xBools(r30)
  # updated ID count in variables
  # cleared bools

  # r3 = bools (before cleared)
  # r4 still = first player GObj

  beq- _end_of_cliffcatch_update
  # unlikely case where GObj chain count does not match the previous frame
  # -- indicates bool index may be misaligned, so logic is delayed until they can be rechecked

  bl _recursive_cliffcatch_by_distance
  # fancy parse function deals with all the dirty details

  _end_of_cliffcatch_update:
  li r0, close
  stw r0, xGate(r30)
  lwz r30, 0x2C(r29)
  # close cliffcatch action gate, so that bools can reaccumilate for next check

_return:
mr    r3, r29