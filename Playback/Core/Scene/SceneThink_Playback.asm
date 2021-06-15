################################################################################
# Address: 801a6348
################################################################################
.include "Common/Common.s"
.include "Playback/Playback.s"

.set REG_Floats, 30
.set REG_BufferPointer, 29
.set REG_Text,28
.set REG_FrameCount,27

#############################
# Create Per Frame Function #
#############################

#Check If Major Scene 0xE
  load  r3,0x80479D30   #Scene Controller
  lbz r3,0x0(r3)        #Major Scene ID
  cmpwi r3,0xE          #DebugMelee
  bne Original

#Create GObj
  li  r3, 13
  li  r4,14
  li  r5,0
  branchl r12, GObj_Create

#Schedule Function
  bl  PlaybackThink
  mflr  r4      #Function to Run
  li  r5,0      #Priority
  branchl r12, GObj_AddProc

b Exit



###########################
# Playback Think Function #
###########################

PlaybackThink:
blrl

  backup

  ##############################
  ## Start Error Message Init ##
  ##############################

#Get Float Values
  bl  FloatValues
  mflr  REG_Floats

#Create Text Struct
  li  r3,0
  li  r4,-1
  branchl r12, Text_CreateStruct

#BACKUP STRUCT POINTER
  mr REG_Text,r3

#SET TEXT KERNING TO CLOSE
  li r4,0x1
  stb r4,0x49(REG_Text)
#SET TEXT TO ALIGN LEFT @ X LOCATION
  li r4,0x0
  stb r4,0x4A(REG_Text)

#Store Base Z Offset
  lfs f1,TextZPos(REG_Floats) #Z offset
  stfs f1,0x8(REG_Text)

#Scale Canvas Down
  lfs f1,CanvasScaling(REG_Floats)
  stfs f1,0x24(REG_Text)
  stfs f1,0x28(REG_Text)

  ######################
  ## Print Lines Loop ##
  ######################

#Initialize Subtext
  lfs   f1,TextXPos(REG_Floats)     #X offset of text
  lfs   f2,TextYPos(REG_Floats)     #Y offset of text
  mr    r3,REG_Text                 #struct pointer
  bl    Text
  mflr  r4
  bl    Dots
  mflr  r5
  branchl r12, Text_InitializeSubtext
#Change scale
  mr  r4,r3
  mr  r3,REG_Text
  lfs f1,TextScale(REG_Floats)
  lfs f2,TextScale(REG_Floats)
  branchl r12, Text_UpdateSubtextSize

#Initialize Watermark
  lfs   f1,WatermarkX(REG_Floats)     #X offset of text
  lfs   f2,WatermarkY(REG_Floats)     #Y offset of text
  mr    r3,REG_Text                 #struct pointer
  bl    Watermark
  mflr  r4
  branchl r12, Text_InitializeSubtext
#Change scale
  mr  r4,r3
  mr  r3,REG_Text
  lfs f1,TextScale(REG_Floats)
  lfs f2,TextScale(REG_Floats)
  branchl r12, Text_UpdateSubtextSize
#Change color
  load  r3,0x2ECC40FF
  stw r3,0x40(sp)
  mr  r3,REG_Text
  li  r4,1
  addi r5,sp,0x40
  branchl r12, Text_ChangeTextColor

  #####################
  ## Allocate Buffer ##
  #####################

  li  r3,EXIBufferLength
  branchl r12, HSD_MemAlloc
  mr  REG_BufferPointer,r3

  ######################
  ## Init Frame Count ##
  ######################

  li  REG_FrameCount,0

  ########################
  ## Message Think Loop ##
  ########################

  PlaybackThink_Loop:
    branchl r12, GXInvalidateVtxCache
    branchl r12, GXInvalidateTexAll

    li  r3,0x0
    branchl r12, HSD_StartRender

    lwz r3,HideWaitingForGame(rtoc)
    cmpwi r3, 0
    bne skipDraw
    li  r3,0x0
    mr  r4,REG_Text
    branchl r12, Text_DrawEachFrame
  skipDraw:
    li  r3,0x0
    branchl r12, HSD_VICopyXFBASync

    # Explicit wait frame. Without this, if Normal Lag Reduction was on,
    # this scene would go into hyper-drive
    branchl r12, VIWaitForRetrace

  ##########################
  ## Update ... Animation ##
  ##########################

  #Update counter
    addi REG_FrameCount,REG_FrameCount,1    #increment frame count
    cmpwi REG_FrameCount,240
    blt PlaybackThink_GetDotString
  #Reset to 0
    li  REG_FrameCount,0

  PlaybackThink_GetDotString:
    li  r3,60
    divwu r3,REG_FrameCount,r3
    bl  Dots
    mflr r4
    mulli r3,r3,0x4
    add r6,r3,r4

  #Update String
    mr r3,REG_Text
    li  r4,0
    bl  Text
    mflr r5
    crclr 6
    branchl r12, Text_UpdateSubtextContents

  ####################
  ## Check For EXI ##
  ###################

  PlaybackThink_CheckEXI:
  RequestReplay:
    li r3,CMD_IS_REPLAY_READY
    stb r3,0x0(REG_BufferPointer)
    mr r3,REG_BufferPointer
    li  r4,0x1                #Length
    li  r5,CONST_ExiWrite
    branchl r12,FN_EXITransferBuffer
  ReceiveReplay:
    mr r3,REG_BufferPointer
    li  r4,0x1                #Length
    li  r5,CONST_ExiRead
    branchl r12,FN_EXITransferBuffer
  #Wait For Replay to be Ready
    lbz r3,0x0(REG_BufferPointer)
    cmpwi r3,0x1
    bne PlaybackThink_Loop

  ###############
  ## Exit Loop ##
  ###############

  PlaybackThink_ExitLoop:

  #Remove Text
    mr  r3,REG_Text
    branchl r12, Text_RemoveText

  # get the game info data
  REQUEST_DATA:
  # request game information from slippi
    li r3,CMD_GET_GAME_INFO        # store game info request ID
    stb r3,0x0(REG_BufferPointer)
  # write memory locations to preserve when doing mem savestates
    li r3, 0  # wont be savestating yet so maybe 0 is a valid argument here =)
    stw r3, 0x1(REG_BufferPointer)
    li r3, 0  # include the latest frame which follows SFXDB, wont be savestating yet so maybe 0 is a valid argument here =) 
    stw r3, 0x5(REG_BufferPointer)
    li r3, 0
    stw r3, 0x9(REG_BufferPointer)
  # Transfer buffer over DMA
    mr r3,REG_BufferPointer   #Buffer Pointer
    li  r4,0xD            #Buffer Length
    li  r5,CONST_ExiWrite
    branchl r12,FN_EXITransferBuffer
  RECEIVE_DATA:
  # Transfer buffer over DMA
    mr  r3,REG_BufferPointer
    li  r4,GameInfoLength     #Buffer Length
    li  r5,CONST_ExiRead
    branchl r12,FN_EXITransferBuffer
  # Check if successful
    lbz r3,0x0(REG_BufferPointer)
    cmpwi r3, 1
    beq READ_DATA
  # Wait a frame before trying again? idk i copied this from RestoreGameInfo.asm lol
    branchl r12, VIWaitForRetrace
    b REQUEST_DATA
  READ_DATA:
  .set REG_MatchInfo, 20
    addi REG_MatchInfo,REG_BufferPointer,MatchStruct #Match info from slippi

  # Preload these fighters
    load r4,0x80432078
    lbz r3, 0x60(REG_MatchInfo) # load p1 char id
    stw r3, 0x14 (r4)
    lbz r3, 0x63(REG_MatchInfo) # load char color
    stb r3, 0x18 (r4)
    lbz r3, 0x60 + 0x24(REG_MatchInfo) # load p2 char id
    stw r3, 0x1C (r4)
    lbz r3, 0x63 + 0x24(REG_MatchInfo) # load char color
    stb r3, 0x20 (r4)
    lbz r3, 0x60 + 0x24*2(REG_MatchInfo) # load p3 char id
    stw r3, 0x24 (r4)
    lbz r3, 0x63 + 0x24*2(REG_MatchInfo) # load char color
    stb r3, 0x28 (r4)
    lbz r3, 0x60 + 0x24*3(REG_MatchInfo) # load p4 char id
    stw r3, 0x2C (r4)
    lbz r3, 0x63 + 0x24*3(REG_MatchInfo) # load char color
    stb r3, 0x30 (r4)

  SKIP_TEAMS_PRELOAD:
  # Preload the stage
    lhz r3, 0xE (REG_MatchInfo)
    stw r3, 0xC (r4)

  # Queue file loads
    branchl r12,0x80018254
    li  r3,199
    branchl r12,0x80018c2c
    li  r3,4
    branchl r12,0x80017700

  # Clear ssm queue
    li	r3, 28
    branchl	r12, 0x80026F2C

  branchl r12,0x8021b2d8

  # Load fighters' ssm files
  .set REG_COUNT,21
  .set REG_CURR,22
    li	REG_COUNT, 0
    mulli	r0, REG_COUNT, 36
    mr REG_CURR, REG_MatchInfo
    add	REG_CURR, REG_CURR, r0
  CSSSceneDecide_SSMLoop:
  # Get fighter's external ID
    branchl r12,FN_GetFighterNum
    lbz	r4, 0x0060 (REG_CURR)
    extsb	r4, r4
    cmpw r4,r3
    beq CSSSceneDecide_SSMIncLoop
  # Get fighter's ssm ID
    li r3,0   # fighter
    # r4 already contains fighter index
    branchl r12,FN_GetSSMIndex
    branchl r12,FN_RequestSSM   # queue it
  CSSSceneDecide_SSMIncLoop:
    addi	REG_COUNT, REG_COUNT, 1
    cmpwi	REG_COUNT, 6
    addi	REG_CURR, REG_CURR, 36
    blt+	 CSSSceneDecide_SSMLoop
  # Get stage's ssm file index
    lhz r3, 0xE (REG_MatchInfo)
    branchl r12,0x8022519c  # get internal ID
    mr r4,r3  # stage index
    li r3,1   # stage
    branchl r12,FN_GetSSMIndex
    branchl r12,FN_RequestSSM   # queue it
  # set to load
    branchl r12, 0x80027168

  #Play SFX
    lwz r3,HideWaitingForGame(rtoc)
    cmpwi r3, 0
    bne skipSFX
    li  r3,0x1
    branchl r12, SFX_Menu_CommonSound
  skipSFX:
  
  #Resume
    branchl r12, DiscError_ResumeGame

  #Change Scene Minor
    branchl r12, MenuController_ChangeScreenMinor

  b PlaybackThink_Exit

######################################################

FloatValues:
  blrl
#Offsets
  .set TextXPos,0x0
  .set TextYPos,0x4
  .set TextZPos,0x8
  .set TextScale,0xC
  .set CanvasScaling,0x10
  .set WatermarkX,0x14
  .set WatermarkY,0x18
  .set DotX,0x1C
  .set DotY,0x20
#Values
  .float -190   #text X pos
  .float 0      #text Y pos
  .float 0      #Z offset
  .float 1      #text scale
  .float 0.6    #Canvas Scaling
#Watermark
  .float 366    #watermark X
  .float 350    #Watermark Y
#Dot
  .float 170
  .float 0

  Text:
  blrl
  .string "Waiting for game%s"
  .align 2

  Dots:
  blrl
  .long 0x00000000
  .string "."
  .align 2
  .string ".."
  .align 2
  .string "..."
  .align 2

  Watermark:
  blrl
  .string "slippi.gg"
  .align 2

  PlaybackThink_Exit:
  restore
  blr

################################################################

##################
# Exit Injection #
###################

Exit:
branch r12,0x801a6368

Original:
lwz r3, 0 (r31)
