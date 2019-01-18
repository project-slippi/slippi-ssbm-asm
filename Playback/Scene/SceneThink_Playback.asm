#To be inserted at 801a6348
.include "../../Common/Common.s"

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
  branchl r12,0x803901f0

#Schedule Function
  bl  PlaybackThink
  mflr  r4      #Function to Run
  li  r5,0      #Priority
  branchl r12,0x8038fd54

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
  branchl r12,0x803a6754

#BACKUP STRUCT POINTER
  mr REG_Text,r3

#SET TEXT KERNING TO CLOSE
  li r4,0x1
  stb r4,0x49(REG_Text)
#SET TEXT TO ALIGN LEFT @ X LOCATION
  li r4,0x0
  stb r4,0x4A(REG_Text)

#Store Base Z Offset
  lfs f1,ZPos(REG_Floats) #Z offset
  stfs f1,0x8(REG_Text)

#Scale Canvas Down
  lfs f1,CanvasScaling(REG_Floats)
  stfs f1,0x24(REG_Text)
  stfs f1,0x28(REG_Text)

  ######################
  ## Print Lines Loop ##
  ######################

#Initialize Subtext
  lfs   f1,XPos(REG_Floats)     #X offset of text
  lfs   f2,YPos(REG_Floats)     #Y offset of text
  mr    r3,REG_Text                 #struct pointer
  bl    Text
  mflr  r4
  bl    Dots
  mflr  r5
  branchl r12,0x803a6b98
#Change scale
  mr  r4,r3
  mr  r3,REG_Text
  lfs f1,TextScale(REG_Floats)
  lfs f2,TextScale(REG_Floats)
  branchl r12,0x803a7548

#Initialize Watermark
  lfs   f1,WatermarkX(REG_Floats)     #X offset of text
  lfs   f2,WatermarkY(REG_Floats)     #Y offset of text
  mr    r3,REG_Text                 #struct pointer
  bl    Watermark
  mflr  r4
  branchl r12,0x803a6b98
#Change scale
  mr  r4,r3
  mr  r3,REG_Text
  lfs f1,TextScale(REG_Floats)
  lfs f2,TextScale(REG_Floats)
  branchl r12,0x803a7548
#Change color
  load  r3,0x2ECC40FF
  stw r3,0x40(sp)
  mr  r3,REG_Text
  li  r4,1
  addi r5,sp,0x40
  branchl r12,0x803a74f0

  ###########################
  ## Allocate Buffer Space ##
  ###########################

  li  r3,0x20
  branchl r12,0x8037f1e4
  mr  REG_BufferPointer,r3

  ######################
  ## Init Frame Count ##
  ######################

  li  REG_FrameCount,0

  ########################
  ## Message Think Loop ##
  ########################

  PlaybackThink_Loop:
    branchl r12,0x8033c898      #GXInvalidateCache
    branchl r12,0x8033f270      #GXInvalidateTexAll

    li  r3,0x0
    branchl r12,0x80375538      #HSD_StartRender

    li  r3,0x0
    mr  r4,REG_Text
    branchl r12,0x803a84bc      #renderTextOnscreen

    li  r3,0x0
    branchl r12,0x803761c0      #HSD_VICopyXFBASync

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
    branchl r12,0x803a70a0

  ####################
  ## Check For EXI ##
  ###################

  PlaybackThink_CheckEXI:
  RequestReplay:
    li r3,CONST_SlippiCmdCheckForReplay
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
    branchl r12,0x803a5cc4

  #Resume
    branchl r12,0x80024f6c

  #Play SFX
    li  r3,0x1
    branchl r12,0x80024030

  #Change Scene Minor
    branchl r12,0x801a4b60

  b PlaybackThink_Exit

######################################################

FloatValues:
  blrl
#Offsets
  .set XPos,0x0
  .set YPos,0x4
  .set ZPos,0x8
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
  .float 160    #watermark X
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
  .string "project-slippi.com"
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
