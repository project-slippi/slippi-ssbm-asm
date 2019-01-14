#To be inserted at 8016e2dc
################################################################################
#                      Inject at address 8016e2dc
# Function is PlayerBlock_LoadPlayers. This fetches the game frame for the
# initial StartMelee spawn points.
################################################################################
.include "../Common/Common.s"
.include "./Playback.s"

################################################################################
#                   subroutine: LoadFirstSpawn
# description: per frame function that will handle fetching the current frame's
# data and storing it to the buffer
################################################################################

# Get GameFrame
  li  r3,0
  branchl r12,FN_FetchGameFrame

Original:
  lbz	r0, 0x0007 (r31)
