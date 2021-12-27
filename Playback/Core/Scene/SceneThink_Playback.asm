################################################################################
# Address: 801a6348
################################################################################
.include "Online/Core/EXIFileLoad/TransferFile.asm"
.include "Playback/Playback.s"

.set REG_Floats, 30
.set REG_BufferPointer, 29
.set REG_Text, 28
.set REG_FrameCount, 27
.set REG_LOCAL_DATA_ADDR, 25
.set REG_CAM_GOBJ, 22
.set REG_LOGO_JOBJ, 21
# .set REG_PROC_GOBJ, 19
.set REG_SLPLOGO, 19
.set REG_LOGO_GOBJ, 18

# symbol offsets
.set SLPLOGO_LOGO_JOBJDESC, 0x0
.set SLPLOGO_CAMDESC, 0x4
.set COBJ_LINKS, 0x20

  bl DATA_BLRL
  mflr REG_LOCAL_DATA_ADDR
  b FBegin


DATA_BLRL:
blrl
# File related strings
.string "slpCSS.dat"
.set DO_STRING_SLPLOGO_FILENAME, 0
.string "slplogo_scene_data"
.set DO_STRING_SLPLOGO_SYMBOLNAME, DO_STRING_SLPLOGO_FILENAME + 11
.align 2

FBegin:

#############################
# Create Per Frame Function #
#############################

#Check If Major Scene 0xE
  load  r3,0x80479D30   #Scene Controller
  lbz r3,0x0(r3)        #Major Scene ID
  cmpwi r3,0xE          #DebugMelee
  bne Original

#Create Cam GObj
  li  r3, 22 #formerly 0
  li  r4, 23 # formerly 14
  li  r5, 0 
  branchl r12, GObj_Create
  mr REG_CAM_GOBJ, r3 # save GOBJ pointer

#Create Logo GObj
  li  r3, 4 
  li  r4, 5
  li  r5, 0x80
  branchl r12, GObj_Create
  mr REG_LOGO_GOBJ, r3 # save GOBJ pointer

# Create Proc GOBJ
#  li r3, 13
#  li r4, 14
#  li r5, 0
#  branchl r12, GObj_Create
#  mr REG_PROC_GOBJ, r3 # save GOBJ pointer

# Load LOGO file
  addi r3, REG_LOCAL_DATA_ADDR, DO_STRING_SLPLOGO_FILENAME
  branchl r12,0x80016be0 # File_Load

# Retrieve symbol from file data
  addi r4, REG_LOCAL_DATA_ADDR, DO_STRING_SLPLOGO_SYMBOLNAME
  branchl r12,0x80380358 # HSD_ArchiveGetPublicAddress, returns a pointer in r3
  mr REG_SLPLOGO, r3 # Remember symbol pointer

# Load camdesc
  lwz r3, SLPLOGO_CAMDESC (REG_SLPLOGO) 
  lwz r3, 0x0 (r3) # r3 becomes Camera_
  branchl r12,0x8036a590 # CObj_LoadDesc (i assume it returns into r3) 

# Add COBJ to GOBJ
  mr r5, r3 # Move COBJ pointer to r5
  lbz r4, 4 # -0x3E55(r13)
  mr r3, REG_CAM_GOBJ
  branchl r12, GObj_AddToObj # void GObj_AddObject(GOBJ *gobj, u8 unk, void *object)

# Initialize camera
  mr r3, REG_CAM_GOBJ # Might be redundant, but it's unclear whether GObj_AddToObj backs-up/restores register 3
  load r4, 0x803910D8 # CObjThink_Common
  li r5, 1 # gx_pri
  branchl r12, 0x8039075C # void GObj_InitCamera(GOBJ* gobj, void (*render_cb)(GOBJ*, s32), u32 priority)

# set gobj->cobj_links (0x20) to 1 << gx link index (9)
  li r4, 512
  stw r4, COBJ_LINKS(REG_CAM_GOBJ)

# Load logo JOBJ
  lwz r3, 0x0 (REG_SLPLOGO) # r3 = slplogo_scene_data
  lwz r3, SLPLOGO_LOGO_JOBJDESC (r3) # r3 becomes JOBJDescs_
  lwz r3, 0x0 (r3) # r3 becomes Array_0_ (HSD_JOBJDesc[]) 
  branchl r12, JObj_LoadJoint # (jobj_desc_ptr)
  mr REG_LOGO_JOBJ,r3

# Add logo JOBJ to GOBJ
  mr r3, REG_LOGO_GOBJ
  # li r4, 0xFF # 0x804db6a0 + -0x3E55 (an offset to obj_kind)
  # stb r4, 0x6(REG_LOGO_GOBJ) # For some reason gobj->obj_kind is an invalid value here (could be heap corruption?), so we fix it by setting it to 0xFF
  # lbz r4, -0x3E55(r13)
  li r4, 4
  mr r5, REG_LOGO_JOBJ
  branchl r12,0x80390a70 # void GObj_AddObject

# Add GX link that draws the logo
  mr r3, REG_LOGO_GOBJ
  load r4, 0x80391070 # GXLink_Common
  li r5, 9 # index
  li r6, 1 # gx_pri, formerly 128
  branchl r12, GObj_SetupGXLink # void GObj_AddGXLink

#Schedule Function
  bl  PlaybackThink
  mr r3, REG_LOGO_GOBJ
  mflr  r4      #Function to Run
  li  r5, 0      #Priority
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

  ###########################
  ## Allocate Buffer Space ##
  ###########################

  li  r3,0x20
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

  #Resume
    branchl r12, DiscError_ResumeGame

  #Play SFX
    lwz r3,HideWaitingForGame(rtoc)
    cmpwi r3, 0
    bne skipSFX
    li  r3,0x1
    branchl r12, SFX_Menu_CommonSound
  skipSFX:
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
  .string "Poggers%s"
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
