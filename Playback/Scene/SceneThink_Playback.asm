#To be inserted at 801a6348
.include "../../Common/Common.s"

.set REG_Floats, 30
.set REG_BufferPointer, 29
.set REG_Text,28
.set REG_FrameCount,27
.set REG_DevelopText,26

#############################
# Create Per Frame Function #
#############################

#Check If Major Scene 0xE
  load  r3,0x80479D30   #Scene Controller
  lbz r3,0x0(r3)        #Major Scene ID
  cmpwi r3,0xE          #DebugMelee
  bne Original

backup

#Create GObj
  li  r3, 13
  li  r4,14
  li  r5,0
  branchl r12, Gobj_Create2

#Schedule Function
  bl  PlaybackThink
  mflr  r4      #Function to Run
  li  r5,0      #Priority
  branchl r12, Gobj_SchedulePerFrameProcess

.set OFST_Text,-0x49ac
.set OFST_Frames,-0x49a8
.set OFST_Buffer,-0x49a4

#Init text pointer variable
  li  r3,0
  stw r3,OFST_Text(r13)
#Init frame count
  li  r3,0
  stw r3,OFST_Frames(r13)
#Allocate Buffer Space
  li  r3,0x20
  branchl r12, HSD_MemAlloc
  stw r3,OFST_Buffer(r13)

#Check if chroma key enabled
  lwz r3,ChromaKeyPlayback(rtoc)
  cmpwi r3,0
  bne InitChromaKey

#####################
## Start Text Init ##
#####################

#Create Text Canvas
  li  r3,0
  li  r4,0
  li  r5,9
  li  r6,13
  li  r7,0
  li  r8,14
  li  r9,0
  li  r10,19
  branchl r12,0x803a611c

#Get Float Values
  bl  FloatValues
  mflr  REG_Floats

#Create Text Struct
  li  r3,0
  li  r4,0
  branchl r12, Text_CreateTextStruct

#BACKUP STRUCT POINTER
  stw r3,OFST_Text(r13)
  mr  REG_Text,r3

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

#################
## Print Lines ##
#################

#Initialize Subtext
  lfs   f1,XPos(REG_Floats)     #X offset of text
  lfs   f2,YPos(REG_Floats)     #Y offset of text
  mr    r3,REG_Text             #struct pointer
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
  b Exit

##############################
## Init chroma key behavior ##
##############################
InitChromaKey:
#Create Rectangle
  li  r3,0x348
  branchl r12,HSD_MemAlloc
  mr  r8,r3
  li  r3,6
  li  r4,-25
  li  r5,-25
  li  r6,20
  li  r7,7
  branchl r12,DevelopText_CreateDataTable
  mr  REG_DevelopText,r3
#Store Develop Text Pointer
  load r3,0x8049fac8
  stw REG_DevelopText,0x0(r3)
#Activate Text
  lwz	r3, -0x4884 (r13)
  mr  r4,REG_DevelopText
  branchl r12,0x80302810

#Get Floats
  bl  FloatValues
  mflr REG_Floats
#Magenta Background
  lwz r3,ChromaColor(REG_Floats)
  stw r3,0x10(REG_DevelopText)
#Set Stretch
  lfs f1,ChromaWidth(REG_Floats)
  stfs f1,0x8(REG_DevelopText)
  lfs f1,ChromaHeight(REG_Floats)
  stfs f1,0xC(REG_DevelopText)
#Hide blinking cursor
  li  r3,0
  stb r3,0x26(REG_DevelopText)

b Exit



###########################
# Playback Think Function #
###########################

PlaybackThink:
blrl

  backup

########################
## Message Think Loop ##
########################

PlaybackThink_Loop:
#Get registers
  lwz REG_Text,OFST_Text(r13)
  lwz REG_FrameCount,OFST_Frames(r13)
  lwz REG_BufferPointer,OFST_Buffer(r13)

#Update ... Animation
#Check if text exists
  cmpwi REG_Text,0
  beq PlaybackThink_CheckEXI
#Update counter
  addi REG_FrameCount,REG_FrameCount,1    #increment frame count
  stw REG_FrameCount,OFST_Frames(r13)
  cmpwi REG_FrameCount,240
  blt PlaybackThink_GetDotString
#Reset to 0
  li  REG_FrameCount,0
  stw REG_FrameCount,OFST_Frames(r13)
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
  bne PlaybackThink_Exit

###############
## Exit Loop ##
###############

PlaybackThink_ExitLoop:
#Remove Text
  cmpwi REG_Text,0
  beq PlaybackThink_ExitLoopSkipTextRemoval
  mr  r3,REG_Text
  branchl r12, Text_RemoveText
PlaybackThink_ExitLoopSkipTextRemoval:

/*
#Remove Develop Text
  load r3,0x8049fac8
  lwz r3,0x0(r3)
  cmpwi r3,0
  beq PlaybackThink_ExitLoopSkipDevelopTextRemoval
#Hides text, i actually dont know how to remove this
  li  r4,0x40
  stb r4,0x26(r3)
PlaybackThink_ExitLoopSkipDevelopTextRemoval:
*/

#Play SFX
  li  r3,0x1
  branchl r12, SFX_Menu_CommonSound

#Change Scene Minor
  branchl r12, MenuController_ChangeScreenMinor

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
  .set ChromaColor,0x24
  .set ChromaWidth,0x28
  .set ChromaHeight,0x2C
#Values
  .float 360    #text X pos
  .float 383    #text Y pos
  .float 0      #Z offset
  .float 1      #text scale
  .float 0.6    #Canvas Scaling
#Watermark
  .float 916    #watermark X
  .float 750    #Watermark Y
#Dot
  .float 170
  .float 0
#Chroma Key Background
  .byte 255,0,255,255   #RGBA
  .float 35
  .float 75

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
restore
branch r12,0x801a6368

Original:
lwz r3, 0 (r31)
