# Required Includes (A file that includes this header must also include these)
# Recording/Recording.s

.macro Macro_SendFrameStart

CreateFrameStartProc:
#Create GObj
  li	r3,4	    	#GObj Type (4 is the player type, this should ensure it runs before any player animations)
  li	r4,7	  	  #On-Pause Function (dont run on pause)
  li	r5,0        #some type of priority
  branchl	r12,GObj_Create

#Create Proc
  bl  SendFrameStart
  mflr r4         #Function
  li  r5,0        #Priority
  branchl	r12,GObj_AddProc

b CreateFrameStartProc_Exit

################################################################################
# Routine: SendFrameStart
# ------------------------------------------------------------------------------
# Description: Sends the RNG seed that is needed for the very rare case of throws
# causing the DamageFlyTop state
################################################################################

SendFrameStart:
blrl

.set REG_PlayerData,31
.set REG_Buffer,29
.set REG_BufferOffset,28
.set REG_PlayerSlot,27
.set REG_GameEndID,26
.set REG_SceneThinkStruct,25

backup

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
# get current offset in buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset

# initial RNG command byte
  li r3, CMD_INITIAL_RNG
  stb r3,0x0(REG_Buffer)

# send frame count
  lwz r3,frameIndex(r13)
  stw r3,0x1(REG_Buffer)

# store RNG seed
  lis r3, 0x804D
  lwz r3, 0x5F90(r3) #load random seed
  stw r3,0x5(REG_Buffer)

# store scene frame counter
  loadGlobalFrame r3
  stw r3, 0x9(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset,(GAME_FRAME_START_PAYLOAD_LENGTH+1)
  stw REG_BufferOffset,bufferOffset(r13)

SendFrameStart_Exit:
  restore
  blr

CreateFrameStartProc_Exit:

.endm
