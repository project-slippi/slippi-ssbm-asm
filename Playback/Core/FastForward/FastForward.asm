################################################################################
# Address: 801a501c
################################################################################

# Injection is right before game engine loops
.include "Common/Common.s"
.include "Playback/Playback.s"
.include "Common/FastForward/FunctionMacros.s"

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
  bl FN_ExecCameraTasks

# do a stupid cmp operation so that the blt at 801a5020 will branch
  cmpwi r3, 0xFF
  b Exit

# Functions section
FunctionBody_ExecCameraTasks # Adds FN_ExecCameraTasks

Exit:
