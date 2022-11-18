blrl
# User options:
.set enabled,        1
# Tech only occurs if code is enabled (can be toggled during game)

.set enforceFacing,  1
# Tech only occurs if players are facing towards eachother

.set enforceHitbox,  0
# Tech only occurs if both grab hitboxes are out (VERY tight windows)

.set grapple,        0
# Tech occurs after grapple action is completed (see Link/Samus)

_0x00:
.float 1.6
# animation speed of CatchCut and CaptureCut

_0x04:
.byte (enabled<<0)+(enforceFacing<<1)+(enforceHitbox<<2)+(grapple<<3)
.align 2

_0x08:
.long 0
# 32-bit array of bools,
# used to keep track of up to 32 player GObjs requiring post-action effects

_0x0C:
_custom_player_aura:
# frame 0:
.long 0x58000000, 0x00000052, 0x00004040 # SFX1
.long 0x58000000, 0x000000F3, 0x00005040 # SFX2
.long 0x54000000, 0x03F90000, 0x00000000, 0x00000000, 0x00000000 # GFX1
.long 0x36000050, 0xFF8000FF # set additive light
.long 0x3C000012, 0xFF800020 # blend light
.long 0x48000000, 0xFFFFFF00 # set overlay
.long 0x4C000012, 0xFFFFFF90 # blend overlay
.long 0x2C000012 # wait out blends
# frame 18:
.long 0x44000000 # kill light
.long 0x4C000018, 0xFFFFFF00 # fade overlay
.long 0x2C000018 # wait for fade
# frame 50:
.long 0x30000000 # kill overlay/lights
.long 0x28000000 # terminate aura




1.02 ------ 800da9d8 --- 4bfa31f5 -> Branch
# bl    ->0x8007DBCC
# just as breakout timer is being assigned as argument for call

# r3 = breakout assignee's player data
# r4 = unk int argument (0 immediate)
# f1 = breakout timer to assign
# r31 is safe to use

# offsets
.set xOptions,    0x4
.set xFXflags,    0x8
.set xFacing,     0x2C
.set xFacingPrev, 0x30
.set xGrabber,    0x1A58
.set xAnimIntr,   0x21A0

# registers
.set rParams,   8
.set rNext,     6
.set rCount,    7
.set rFlags,    5
.set rPData,    3
.set rPlayer,   26
.set rGrabber,  31

# bools
.set bEnabled,     31
.set bCheckFacing, 30
.set bCheckHitbox, 29
.set bGrapple,     28

# other
.set Catch,     0xD4  # ASIDs
.set CatchDash, 0xD6
.set breakoutAnimInterrupt, 0x800dbd10

lwz r0, 0x10(rPData)
cmpwi r0, Catch
cmpwi cr1, r0, CatchDash
cror  eq, eq, eq+4
stw  r0, 0x1C(sp)
bne+ _return
# check for action state
# this will be the most likely to be false, so it's checked first

bl <TGrab_params>
mflr rParams
lbz r0, xOptions(rParams)
mtcrf 0b000001, r0
lwz rGrabber, xGrabber(rPData)
lwz r5, 0x2C(rGrabber)
# rParams and rGrabber have been loaded
# cr7 contains option bools
# r5 holds rGrabber player data
# r3 holds rPlayer player data

_check_enabled:
bf- bEnabled, _return
# /if disabled, then don't do anything

_check_facing:
bf- bCheckFacing, _check_hitbox
  lwz r6, xFacingPrev(rPData)
  lwz r5, xFacing(r5)
  cmpw r6, r5
  beq- _return
  # /if checking facing, return when players are facing the same direction

_check_hitbox:
bf+ bCheckHitbox, _check_grapple
  lbz r0, 0x2219(rPData)
  andi. r5, r0, 0x10
  beq+ _return
  # /if checking for hitbox, only tech if both player's hitboxes are out


_check_grapple:
bt+ bGrapple, _setup_loop
  lis r31, breakoutAnimInterrupt@h
  ori r31, r31, breakoutAnimInterrupt@l
  stw r31, 0x1C(sp)
  # player will not wait for catch to pull player towards grabber

_setup_loop:
lwz r7, -0x3e74(r13)
lwz rNext, 0x20(r7)
li  rCount, 32
lwz rFlags, xFXflags(rParams)
li r0, 0
mtcrf 0b00000001, r0
# registers are ready for loop
# cr7 is cleared

_for_each_player_GObj:
  subic. rCount, rCount, 1
  cmpwi  cr1, rNext, 0
  cror   eq, eq, eq+4
  beq- _exit_loop
  # termination conditions

  cmpw rPlayer, rNext
  lwz  rNext, 0x8(rNext)
  bne+ _for_each_player_GObj
  # iterate loop if player doesn't match rNext

  lis r9, 0x8000
  srw r0, r9, rCount
  or  rFlags, rFlags, r0
  # player has been flagged true for FX memory

_exit_loop:
stw rFlags, xFXflags(rParams)
# update FX memory

lfs f1, -0x7FBC(rtoc)
# set f1 argument to 0 to immediately induce catch cut before the next frame

_return:
bl 0x8007DBCC
# original instruction
.long 0




1.02 ------ 800daa28 --- bb410030 -> Branch
# after action state change, from above function context
# r28 = player being grabbed

.set xAnimIntr, 0x21A0

lwz r31, 0x1C(sp)
cmpwi r31, 0
bge+ _return
# r31 has last been used to load in 0x43300000 for casting purposes
# /if the grapple check was enabled, then it is now set to an address
# MEM1 addresses use the sign bit, so a comparison to 0 is all we need

  _apply_anti_grapple:
  stw r31, xAnimIntr(r28)
  # this sets the animation interrupt to that of a "caught" player
  # for long-distance grabs, like those from link or samus;
  # this will cause the grab to break before grapple pulls the other player

_return:
lmw    r26, 0x0030 (sp)
.long 0



1.02 ------ 800db980 --- 881f234c -> Branch
# lbz    r0, 0x234C (r31)
# just after CatchCut call

# r31 = player data of person who was grabbed
# r30 = player GObj of person who was grabbed

# offsets
.set xAnimSpeed, 0x0
.set xOptions,   0x4
.set xFXflags,   0x8
.set xAura,      0xC
.set xColorReg,  0x408
.set xGrabber,   0x1A58
.set rParams,    3  # registers
.set rGrabber,   4
.set rFlags,     5
.set rNext,      6
.set rCount,     7
.set rPData,     31
.set rPlayer,    30

bl <TGrab_params>
mflr rParams
lwz  rFlags, xFXflags(rParams)
li   r0, 0
cmpwi rFlags, 0
beq+ _return
# do nothing if flags word is empty
# else, set up loop

mtcrf 0b00000001, r0
lwz  rNext, -0x3e74(r13)
stw  r0, xFXflags(rParams)
lwz  rGrabber, xGrabber(rPData)
lwz  rNext, 0x20(rNext)
li   rCount, 32
# FX have been cleared
# cr7 has been cleared
# rFlags = old flags
# ready for loop

_for_each_player_GObj:
  subic. rCount, rCount, 1
  cmpwi  cr1, rNext, 0
  cror   eq, eq, eq+4
  beq- _no_FX
  # termination conditions

  cmpw rPlayer, rNext
  lwz  rNext, 0x8(rNext)
  bne+ _for_each_player_GObj
  # iterate loop if player doesn't match rNext
  # else, exit loop

_exit_loop:
lis r9, 0x8000
srw r0, r9, rCount
and. r9, rFlags, r0
beq+ _no_FX
# /if GObj is found, check for its flag in rFlags
# /if it's TRUE, then apply effects according to user params

  _FX:

  _apply_custom_aura:
  lwz  r11, 0x2C(rGrabber)
  li  r10, 1
  addi r12, rParams, xAura
  li  r0, 0
  stw r10, xColorReg+0x28(rPData)
  stw r0,  xColorReg+0x0(r11)
  stw r12, xColorReg+0x8(rPData)
  stw r10, xColorReg+0x28(r11)
  stw r0,  xColorReg+0x0(rPData)
  stw r12, xColorReg+0x8(r11)
  # custom color auras have been applied to each player

  _apply_custom_animSpeed:
  lfs f1, xAnimSpeed(rParams)
  lfs f2, -0x65e0(rtoc)
  fmuls f1, f1, f2
  lwz r3, xGrabber(rPData)
  bl 0x8006f190
  bl <TGrab_params>
  mflr rParams
  lfs f1, xAnimSpeed(rParams)
  mr r3, rPlayer
  bl 0x8006f190

_no_FX:

_return:
lbz    r0, 0x234C (r31)
.long 0