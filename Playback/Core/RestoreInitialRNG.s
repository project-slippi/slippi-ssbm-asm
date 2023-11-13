#expects: .include "Playback/Playback.s"

.macro Macro_RestoreInitialRNG

CreateInitialRNGProc:
#Create GObj
  li	r3,4	    	#GObj Type (4 is the player type, this should ensure it runs before any player animations)
  li	r4,7	  	  #On-Pause Function (dont run on pause)
  li	r5,0        #object priority
  branchl	r12,GObj_Create

#Create Proc
  bl  RestoreInitialRNG
  mflr r4         #Function
  li  r5,0        #Priority
  branchl	r12,GObj_AddProc

b CreateInitialRNGProc_Exit

################################################################################
# Routine: RestoreInitialRNG
# ------------------------------------------------------------------------------
# Description: Restores the RNG seed that is needed for the very rare case of
# throws causing the DamageFlyTop state
################################################################################

RestoreInitialRNG:
blrl

.set REG_PlayerData,31
.set REG_Buffer,29
.set REG_BufferOffset,28
.set REG_PlayerSlot,27
.set REG_GameEndID,26
.set REG_SceneThinkStruct,25

backup

# check status of initial RNG
  lwz r3,playbackDataBuffer(r13)
  lwz REG_Buffer,PDB_EXI_BUF_ADDR(r3)
  lbz r3,(InitialRNG_Start)+(InitialRNG_Status)(REG_Buffer)
  cmpwi r3,0
  beq RestoreInitialRNG_Exit

# seed exists, so restore it
  lwz r3,(InitialRNG_Start)+(InitialRNG_Seed)(REG_Buffer)
  lis r4, 0x804D
  stw r3, 0x5F90(r4)      #overwrite random seed

RestoreInitialRNG_Exit:
  restore
  blr

CreateInitialRNGProc_Exit:

.endm
