#To be inserted at 8016d298
################################################################################
#                      Inject at address 8016d298
# Function is SceneThink_VSMode and we're calling FetchGameFrame to update
# the frameDataBuffer.
################################################################################
.include "../Common/Common.s"

#Functions
.set FetchGameFrame,0x800055f4

#Check if game ended
  lbz	r0, 0x0008 (r31)
  cmpwi r3,0x0
  beq Exit

# Get GameFrame
  li  r3,1        #Not initial spawn
  branchl r12,FetchGameFrame

Exit:
# Original Codeline
  lbz	r0, 0x0008 (r31)
