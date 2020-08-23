################################################################################
# Address: 800908f0
################################################################################
.include "Common/Common.s"

.set REG_PlayerData,31
.set REG_Floats,30
.set REG_InputIndex,29
.set REG_PrevInput,28

.set	OFST_PlCo,-0x514C
.set	InputIndex,0x804c1f78
.set	InputArray,0x8046b108
.set	PlayerBlock_LoadPlayerGObj,0x8003418c

# Check for toggle bool
	lbz r5,0x618(REG_PlayerData)        #get player port
	subi r4,rtoc,ControllerFixOptions   #get UCF toggle bool base address
	lbzx r4,r4,r5        #get players UCF toggle bool
	cmpwi r4,0x1
	beq Init # if equal, skip to start of handler
# Check for dashback bool (set by slp playback)
	subi r4,rtoc,DashbackOptions
	lbzx r4,r4,r5
	cmpwi r4,0x1
	beq Init
# UCF not enabled, perform original behavior
	lwz	r4, OFST_PlCo (r13)
	lwz	r0, 0x0214 (r4)
	lbz	r3, 0x0670 (REG_PlayerData)
	b	Exit_Without_Restore

.set REG_PlayerData,31
.set REG_InputIndex,30
.set REG_PrevInput,29
.set REG_HSDPad,28
Init:

backup

#Cardinal direction held check:
# 0 = successful vanilla wiggle (branch out with cr0 less than bit true)
# 1 = continue to check additional conditions
# 2+ = wiggle fail due to input held, (branch out with cr0 less than bit false)

	lbz	r3, 0x0670 (REG_PlayerData)
  cmpwi r3, 1
  bne- END

#Ensure last frame < 0.8
  lfs f1,0x628(REG_PlayerData)
  fabs f1,f1
  lwz r3,OFST_PlCo(r13)
  lfs f2,0x210(r3)
  fcmpo cr0,f1,f2
  bge END

BEGIN_HW_INPUTS:
    load REG_HSDPad,HSD_Pad
    lbz REG_InputIndex,0x1(REG_HSDPad)    # HSD_PadRenewMasterStatus gets index for which inputs to get from here

LOAD_2_FRAMES_PAST_INPUTS:
    subi r3, REG_InputIndex, 2
    lbz r4, 0x618(REG_PlayerData)   # load controller port
    bl FETCH_INPUT
    mr    REG_PrevInput,r3
LOAD_CURRENT_FRAME_INPUT:
    mr r3,REG_InputIndex
    lbz r4, 0x618(REG_PlayerData)   # load controller port
    bl FETCH_INPUT

CALCULATE_DIFFERENCE:
    sub    r3,r3,REG_PrevInput
    mullw r3, r3, r3  # Take square to get positive value for comparison
THRESHOLD_TEST:
    li r4, 0x15F9
    cmpw r4, r3
    b END
###################
FETCH_INPUT:   # Gets hw input according to controller port and frame index in r5
#r3 = index
#r4 = controller port

#Backup controller port
    mr    r5,r4
#FIX_INDEX_AND_CHECK_IF_LESS_THAN_ZERO
    subi r3, r3, 1
    cmpwi r3,0
    bge- GET_INPUT
#INDEX_IS_ZERO
    addi r3, r3, 5

GET_INPUT:
    lwz r4,0x8(REG_HSDPad)
    mulli r3, r3, 48
    add r4, r4, r3  # Add index to get inputs from the right frame
    mulli r3, r5, 0xC
    add r4, r4, r3
    lbz r3, 0x02(r4)   # load x-input
    extsb r3, r3    # convert to 32-bit signed int
  FETCH_INPUT_EXIT:
  	blr
###################

END:
  restore

Exit_Without_Restore:
