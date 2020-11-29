################################################################################
# Address: 801a501c
################################################################################

# Injection is right before game engine loops
.include "Common/Common.s"
.include "Playback/Playback.s"

# Info provided by tauKhan, relevant for fast forwarding
# 801a4db0: transfer input queue count to r27
# 801a4de4: engine loop start
# 801a501c: Engine loop check against the initial queue count, loop end
# 801a5024: screen render start

# scene controller checks. must be in VS mode (major) and in-game (minor)
  lis r4, 0x8048 # load address to offset from for scene controller
  lbz r3, -0x62D0(r4)
  cmpwi r3, 0xe # the major scene for playback match
  bne- PreviousCodeLine # if not in VS Mode, ignore everything
  lbz r3, -0x62CD(r4)
  cmpwi r3, 0x1 # the minor scene for in-game is 0x1
  bne- PreviousCodeLine

# ensure game is not paused
  li  r3,1
  branchl r12,CheckIfGameEnginePaused
  cmpwi r3,0x2
  beq PreviousCodeLine

# check status for fast forward
  lwz r3,primaryDataBuffer(r13) # directory address
  lwz r3,PDB_EXI_BUF_ADDR(r3) # EXI buf address
  lbz r3,(BufferStatus_Start)+(BufferStatus_Status)(r3)
  cmpwi r3, CONST_FrameFetchResult_FastForward
  beq FastForward # If we are not terminating, skip

# execute normal code line
PreviousCodeLine:
# unmute  music and SFX
  li  r3,1
  li  r4,2
  branchl r12,Audio_AdjustMusicSFXVolume
  cmpw r26, r27
  b Exit

FastForward:
# black screen
  #li  r3,1
  #branchl r12,VISetBlack
# mute music and SFX
  lwz r3,primaryDataBuffer(r13) # directory address
  lwz r3,PDB_EXI_BUF_ADDR(r3) # EXI buf address
  lbz r3,(RBStatus_Start)+(RBStatus_Status)(r3)
  cmpwi r3, 1
  beq SkipMute # If we are rb, skip mute

  li  r3,0
  li  r4,0
  branchl r12,Audio_AdjustMusicSFXVolume

SkipMute:
# try to execute update camera functions
  branchl r12,0x80030a50 # Camera_LoadCameraEntity

  # The commented line under is the parent function for all this bullshit
  # we need to call to keep gameplay logic in-sync during a ffw. Unfortunately
  # calling it directly makes FFW speed over 3x worse. This likely means there
  # are some minor bugs while FFW'ing since ideally we would call this function.
  # Additionally calling this function causes a bunch of flashing during rollbacks
  # with stuff becoming invisible and coming back in
  # branchl r12,0x800301d0 # DrawCamera+ECBDevelopBoxes

  branchl r12,0x8002a4ac # Updates camera values used in tag position calculation

# call Player_SetOffscreenBool for all characters. This happens as part of the
# camera tasks after the main updateFunction loop so it doesn't run during
# a FFW normally. It is responsible for deciding whether to display the
# offscreen bubble
  bl FN_ProcessGX

# do a stupid cmp operation so that the blt at 801a5020 will branch
  cmpwi r3, 0xFF
  b Exit

# Routine: Set all offscreen bools
FN_ProcessGX:
  backup


branchl r12,0x8021b2d8

  # Set current CObj to main camera. This is for a condition in
  # Player_SetOffscreenBool at line 80086ad4
  branchl r12,0x80030a50 # Camera_LoadCameraEntity
  lwz r3, 0x28(r3)
  branchl r12, 0x80368458 # HSD_CObjSetCurrent

FNPGX_LoopStart:
.set REG_FighterGObj, 20
.set REG_FighterData, 21
# Get first created fighter gobj
  lwz	r3, -0x3E74 (r13)
  lwz	REG_FighterGObj, 0x0020 (r3)
  b FNPGX_LoopCheck
FNPGX_Loop:
# get data
  lwz REG_FighterData,0x2C(REG_FighterGObj)

# if not sleep, update camera stuff
  lbz r3,0x221F(REG_FighterData)
  rlwinm. r0,r3,0,0x10
  bne FNPGX_Loop_NoOffscreen
  mr  r3,REG_FighterGObj
  branchl r12, 0x80086a8c # Player_SetOffscreenBool
FNPGX_Loop_NoOffscreen:

FNPGX_LoopNext:
# get next gobj
  lwz	REG_FighterGObj, 0x8 (REG_FighterGObj)
FNPGX_LoopCheck:
# if gobj exists, process it
  cmpwi REG_FighterGObj,0
  bne FNPGX_Loop

  restore
  blr

Exit:
