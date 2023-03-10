.ifndef HEADER_PREVENT_WOBBLING

.macro Wobbling_InitWobbleCount
.include "Common/Common.s"

.set  REG_DefenderData,29

.set OFST_WobbleCounter,0x2384
.set OFST_LastMoveID,0x2386

#Init count
  li  r3,0
  stb r3,OFST_WobbleCounter(REG_DefenderData)
#Init last move ID
  li  r3,-1
  sth r3,OFST_LastMoveID(REG_DefenderData)
.endm

.macro Wobbling_Check
.include "Common/Common.s"

.set  REG_DefenderData,27

.set ASID_CapturePulledHi, 0xDF
.set ASID_CaptureDamageLw, 0xE4
.set ASID_CaptureJump, 0xE6

.set OFST_IsLeader,0x2222
.set Bitflag_IsLeader,0x4
.set OFST_IsDead,0x221f
.set Bitflag_IsDead,0x40
.set OFST_IsFrozen,0x2219
.set Bitflag_IsFrozen,0x04

.set OFST_WobbleCounter,0x2384
.set OFST_LastMoveID,0x2386
.set MaxWobbles,3

.set Match_CheckIfTeams,0x8016B168
.set AS_218_CatchCut,0x800da698
.set AS_CaptureJump,0x800dc070
.set ActionStateChange,0x800693ac
.set AirStoreBoolLoseGroundJump,0x8007d5d4
.set PlayerBlock_LoadDataOffset,0x8003418C
.set IceClimbers_CheckNanaAliveAndActionable, 0x8012300c

.set Wobbling_Exit,0x8008F0C8

# injecting upon entering capturedamage

  #Ensure im being held in a grab (not thrown)
    lwz r3,0x10(REG_DefenderData)
    cmpwi r3,ASID_CapturePulledHi
    blt Original
    cmpwi r3,ASID_CaptureDamageLw
    bgt Original
  #Get grabber data
    lwz r3,0x1A58(REG_DefenderData)
    cmpwi r3,0
    beq Original
    lwz r4,0x2C(r3)
  #Ensure grabber has a follower
    lbz r4,OFST_IsLeader(r4)
    rlwinm. r4,r4,0,Bitflag_IsLeader
    beq Original
/*
    lbz r3,0xC(r3)
    li  r4,1
    branchl r12,PlayerBlock_LoadDataOffset
    cmpwi r3,0
    beq Original
*/
  #Check if the person who damaged me IS that fighter
    lwz r4,0x1868(REG_DefenderData)
    cmpw  r3,r4
    beq IsFollower
  #Check if its an item
    lhz r5,0x0(r4)
    cmpwi  r5,6
    bne Original
  IsItem:
  #Check if the item belongs to the fighter
    lwz r5,0x2C(r4)
    lwz r4,0x518(r5)
    cmpw  r3,r4
    bne  Original
  #Check if this is the same move i was last hit with
    lhz r3,0xDA8(r5)
    lhz r4,OFST_LastMoveID(REG_DefenderData)
    cmpw  r3,r4
    beq Original
  #Increment wobble count
    b UpdateWobbleCount
  IsFollower:
  #Check if this is the same move i was last hit with
    lwz r5,0x2C(r3)
    lhz r3,0x2088(r5)
    lhz r4,OFST_LastMoveID(REG_DefenderData)
    cmpw  r3,r4
    beq Original
  UpdateWobbleCount:
  #Update last move id
    sth r3,OFST_LastMoveID(REG_DefenderData)
  #Increment wobble count by 1
    lbz r3,OFST_WobbleCounter(REG_DefenderData)
    addi  r3,r3,1
    stb r3,OFST_WobbleCounter(REG_DefenderData)
  #Only in singles
    branchl  r12,Match_CheckIfTeams
    cmpwi r3,0
    bne Original
  #Check if wobble count exceeds max
    lbz r3,OFST_WobbleCounter(REG_DefenderData)
    cmpwi r3,MaxWobbles
    ble Original

  .set REG_GrabberGObj, 20
  .set REG_FollowerGObj, 21
    backup
  #Break this grab
    lwz REG_GrabberGObj,0x1A58(REG_DefenderData)
    mr r3,REG_GrabberGObj
    branchl  r12,AS_218_CatchCut
  #Enter Nana into catchcut as well
    lwz r3,0x2C(REG_GrabberGObj)  #Get grabber data
    lbz r3,0xC(r3)
    li  r4,1
    branchl r12,PlayerBlock_LoadDataOffset
    cmpwi r3,0
    beq SkipBreak
    mr REG_FollowerGObj,r3
  #Check if her AI is in follow mode
    #lbz r5, 0x1a88 + 0xFA (r4)
    #rlwinm. r5,r5,0,0x01
    #beq SkipBreak
  #Ensure that she is alive and actionable
    lwz r4,0x2c(REG_FollowerGObj)
    lbz	r0, OFST_IsDead (r4) # dead flag
    rlwinm.	r0, r0, 0, Bitflag_IsDead
    bne SkipBreak
    lbz	r0, OFST_IsFrozen (r4) # frozen flag
    rlwinm.	r0, r0, 0, Bitflag_IsFrozen
    bne SkipBreak
    lbz	r0, 0x2071 (r4) # state kind
    rlwinm	r0, r0, 28, 28, 31
    cmpwi r0, 13 # star and screen KOs
    beq SkipBreak
CheckGroundState:
  #Check grounded/airborne
    lwz r5, 0xE0 (r4)
    cmpwi r5,0
    bne AerialBreak
  GroundBreak:
  #Grounded nana enters catchcut (800da698, r4 is 0)
    li r4,0
    branchl r12,AS_218_CatchCut #0x800da698
    b SkipBreak
  AerialBreak:
  #Aerial nana enters capturejump (800dc070)
    lwz r3,0x2c(REG_FollowerGObj)
    branchl r12,AirStoreBoolLoseGroundJump #0x8007d5d4
  # give velocity
    lwz r3,0x2c(REG_FollowerGObj)
    lwz	r5, -0x514C (r13)
    lfs	f0, 0x0374 (r5)
    lfs f1,0x2c(r3)
    fneg f1,f1
    fmuls f0,f0,f1
    stfs f0, 0x80 (r3)
    lfs	f0, 0x0378 (r5)
    stfs f0, 0x84 (r3)
    lfs	f0, -0x6900 (rtoc)
    stfs	f0, 0x2340 (r3)
  # change state
    lfs	f1, -0x6900 (rtoc)
    lfs	f2, -0x68FC (rtoc)
    fmr	f3, f1
    mr r3, REG_FollowerGObj
    li r4, ASID_CaptureJump
    li r5, 0
    li r6, 0
    branchl r12,ActionStateChange #0x800693ac
  SkipBreak:
    restore
    branch  r12,Wobbling_Exit

  Original:
.endm

.endif
.set HEADER_PREVENT_WOBBLING, 1
