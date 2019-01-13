#To be inserted at 8016d008
################################################################################
#                      Inject at address 8016d008
# Function is SceneThink_VSMode and we're calling FetchGameFrame to update
# the frameDataBuffer.
################################################################################
.include "../Common/Common.s"

#Functions
.set FetchGameFrame,0x800055f4

# Get GameFrame
  li  r3,1        #Not initial spawn
  branchl r12,FetchGameFrame

Exit:
# Original Codeline
  lwz	r0, -0x6C98 (r13)
