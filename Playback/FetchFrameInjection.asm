#To be inserted at 8016d298
################################################################################
#                      Inject at address 8016d298
# Function is SceneThink_VSMode and we're calling FetchGameFrame to update
# the frameDataBuffer.
################################################################################
.include "../Common/Common.s"
.include "Playback.s"

#Check if game ended. This isn't really strictly required except that without
#it we try to fetch a frame that doesn't exist at the end of the game.
#That causes problems when mirroring because we haven't gotten a game
#end message yet so the game will have to hang temporarily before GAME can be
#shown
  lbz	r0, 0x0008 (r31)
  cmpwi r0,0x0
  bne Exit # r0 is 2 on successful game end

# Get GameFrame
  li  r3,1        #Not initial spawn
  branchl r12,FN_FetchGameFrame

Exit:
# Original Codeline
  lbz	r0, 0x0008 (r31)
