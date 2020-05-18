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
/*
# unmute  music and SFX
  li  r3,1
  li  r4,2
  branchl r12,Audio_AdjustMusicSFXVolume
*/
  cmpw r26, r27
  b Exit

FastForward:
# black screen
  #li  r3,1
  #branchl r12,VISetBlack
# mute music and SFX
/*
  li  r3,0
  li  r4,0
  branchl r12,Audio_AdjustMusicSFXVolume
*/

# try to execute update camera functions
  branchl r12,0x80030a50 # Camera_LoadCameraEntity
  branchl r12,0x8002a4ac # Updates camera values used in tag position calculation

# call Player_SetOffscreenBool for all characters. This happens as part of the
# camera tasks after the main updateFunction loop so it doesn't run during
# a FFW normally. It is responsible for deciding whether to display the
# offscreen bubble
  bl FN_SetOffscreenBools

# do a stupid cmp operation so that the blt at 801a5020 will branch
  cmpwi r3, 0xFF
  b Exit

# Routine: Set all offscreen bools
FN_SetOffscreenBools:
  backup

  load r31, 0x80453080
  li r30, 0

  # Set current CObj to main camera. This is for a condition in
  # Player_SetOffscreenBool at line 80086ad4
  branchl r12,0x80030a50 # Camera_LoadCameraEntity
  lwz r3, 0x28(r3)
  branchl r12, 0x80368458 # HSD_CObjSetCurrent

FNSOB_LoopStart:
  lwz r3, 0xB0(r31)
  cmpwi r3, 0
  beq FNSOB_LoopContinue

  branchl r12, 0x80086a8c # Player_SetOffscreenBool

FNSOB_LoopContinue:
  addi r30, r30, 1
  addi r31, r31, 0xE90
  cmpwi r30, 4
  blt FNSOB_LoopStart

  restore
  blr

Exit:
