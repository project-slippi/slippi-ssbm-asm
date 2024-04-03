# struct offsets
.set  OFST_CMD,0x0
.set  OFST_FRAME,OFST_CMD+0x1
.set  OFST_ID,OFST_FRAME+0x4
.set  OFST_STATE,OFST_ID+0x2
.set  OFST_DIRECTION,OFST_STATE+0x1
.set  OFST_XVELOCITY,OFST_DIRECTION+0x4
.set  OFST_YVELOCITY,OFST_XVELOCITY+0x4
.set  OFST_XPOS,OFST_YVELOCITY+0x4
.set  OFST_YPOS,OFST_XPOS+0x4
.set  OFST_DMGTAKEN,OFST_YPOS+0x4
.set  OFST_EXPIRETIME,OFST_DMGTAKEN+0x2
.set  OFST_SPAWNID,OFST_EXPIRETIME+0x4
.set  OFST_METADATA_1,OFST_SPAWNID+0x4
.set  OFST_METADATA_2,OFST_METADATA_1+0x1
.set  OFST_METADATA_3,OFST_METADATA_2+0x1
.set  OFST_METADATA_4,OFST_METADATA_3+0x1
.set  OFST_OWNER,OFST_METADATA_4+0x1
.set  OFST_INSTANCE,OFST_OWNER+0x1
.set  ITEM_STRUCT_SIZE,OFST_INSTANCE+0x2

.macro Macro_SendItemInfo

CreateItemInfoProc:
#Create GObj
  li	r3,4	    	#GObj Type (4 is the player type, this should ensure it runs before any player animations)
  li	r4,7	  	  #On-Pause Function (dont run on pause)
  li	r5,0        #some type of priority
  branchl	r12,GObj_Create

#Create Proc
  bl  SendItemInfo
  mflr r4         #Function
  li  r5,15        #Priority
  branchl	r12,GObj_AddProc

b CreateItemInfo_Exit

################################################################################
# Routine: SendItemInfo
# ------------------------------------------------------------------------------
# Description: Sends data about each active item
################################################################################

SendItemInfo:
blrl

.set REG_Buffer,31
.set REG_BufferOffset,30
.set REG_ItemGObj,29
.set REG_ItemData,28
.set REG_ItemCount,27

backup

#------------- INITIALIZE -------------
# here we want to initalize some variables we plan on using throughout
# get current offset in buffer
  lwz r3, primaryDataBuffer(r13)
  lwz REG_Buffer, RDB_TXB_ADDRESS(r3)
  lwz REG_BufferOffset,bufferOffset(r13)
  add REG_Buffer,REG_Buffer,REG_BufferOffset
  li  REG_ItemCount,0

# get first created item
  lwz r3,-0x3E74 (r13)
  lwz REG_ItemGObj,0x24(r3)
  cmpwi REG_ItemGObj,0
  beq SendItemInfo_Exit

SendItemInfo_AddToBuffer:
# check if exceeds item limit
  addi  REG_ItemCount,REG_ItemCount,1
  cmpwi REG_ItemCount,MAX_ITEMS
  bgt SendItemInfo_Exit

# get item data
  lwz REG_ItemData,0x2C(REG_ItemGObj)

# check if blacklisted item

# send data
# initial RNG command byte
  li r3, CMD_ITEM
  stb r3,OFST_CMD(REG_Buffer)
# send frame count
  lwz r3,frameIndex(r13)
  stw r3,OFST_FRAME(REG_Buffer)
# store item ID
  lwz r3,0x10(REG_ItemData)
  sth r3,OFST_ID(REG_Buffer)
# store item state
  lwz r3,0x24(REG_ItemData)
  stb r3,OFST_STATE(REG_Buffer)
# store item direction
  lwz r3,0x2C(REG_ItemData)
  stw r3,OFST_DIRECTION(REG_Buffer)
# store item XVel
  lwz r3,0x40(REG_ItemData)
  stw r3,OFST_XVELOCITY(REG_Buffer)
# store item YVel
  lwz r3,0x44(REG_ItemData)
  stw r3,OFST_YVELOCITY(REG_Buffer)
# store item XPos
  lwz r3,0x4C(REG_ItemData)
  stw r3,OFST_XPOS(REG_Buffer)
# store item YPos
  lwz r3,0x50(REG_ItemData)
  stw r3,OFST_YPOS(REG_Buffer)
# store item damage taken
  lwz r3,0xC9C(REG_ItemData)
  sth r3,OFST_DMGTAKEN(REG_Buffer)
# store item expiration
  lwz r3,0xD44(REG_ItemData)
  stw r3,OFST_EXPIRETIME(REG_Buffer)
# store item spawn ID
  lwz r3,0x1C(REG_ItemData)
  stw r3,OFST_SPAWNID(REG_Buffer)
# store misc item data 0xDD4 -> 0xDF4
  lbz r3,0xDD7(REG_ItemData) # This stores Samus missile type
  stb r3,OFST_METADATA_1(REG_Buffer)
  lbz r3,0xDDB(REG_ItemData) # This stores Turnip's face ID
  stb r3,OFST_METADATA_2(REG_Buffer)
  lbz r3,0xDEB(REG_ItemData) # This stores isLaunched bool for Samus/MewTwo
  stb r3,OFST_METADATA_3(REG_Buffer)
  lbz r3,0xDEF(REG_ItemData) # This stores charge power for Samus/MewTwo (0-7)
  stb r3,OFST_METADATA_4(REG_Buffer)
# Store item ownership
  lwz r3, 0x518(REG_ItemData)
  cmpwi r3, 0x0   # Is this a null pointer?
  beq DontFollowItemOwnerPtr
  lwz r3, 0x2C(r3)
  cmpwi r3, 0x0   # Is this a null pointer?
  beq DontFollowItemOwnerPtr
  lbz r3, 0xC(r3)
  b SendItemOwner
DontFollowItemOwnerPtr:
  li r3, -1
SendItemOwner:
  stb r3, OFST_OWNER(REG_Buffer)
# store item instance
  lhz r3,0xDA8(REG_ItemData)
  sth r3,OFST_INSTANCE(REG_Buffer)

#------------- Increment Buffer Offset ------------
  lwz REG_BufferOffset,bufferOffset(r13)
  addi REG_BufferOffset,REG_BufferOffset, ITEM_STRUCT_SIZE
  stw REG_BufferOffset,bufferOffset(r13)

  # Also increment REG_Buffer address for next item write
  addi REG_Buffer,REG_Buffer,ITEM_STRUCT_SIZE

SendItemInfo_GetNextItem:
# get next item
  lwz REG_ItemGObj,0x8(REG_ItemGObj)
  cmpwi REG_ItemGObj,0
  bne SendItemInfo_AddToBuffer


SendItemInfo_Exit:
  restore
  blr

CreateItemInfo_Exit:

.endm
