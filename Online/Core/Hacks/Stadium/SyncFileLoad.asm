################################################################################
# Address: 0x800165ac
################################################################################

.include "Common/Common.s"

.set Stage_GetGObj, 0x801c2ba4
.set File_GetLength, 0x800163d8
.set File_Read, 0x8001668c
.set HSD_MemAllocFromHeap, 0x80015bd0
.set Archive_InitDat, 0x80016a54
.set Archive_GetSymbol, 0x80380358

.set REG_MHEAD, 31
.set REG_MDATA, 30
.set REG_ARCHIVE, 29
.set REG_DATA, 28
.set REG_NAME, 27

.set OFST_BUF, 0xCC
.set OFST_SIZE, 0xC8
.set OFST_BASE, 0x0
.set OFST_HEAD, 0x4
.set OFST_UNKX14, 0x8
.set SZ_ARCHIVE, 68

CODE_START:
  backup
  mr REG_NAME, r3

# get our stage gobj data which holds our archive buffer and size
  li r3, 2
  branchl r12, Stage_GetGObj
  lwz REG_DATA, 0x2C(r3)

# init archive
  mr r3, REG_NAME
  branchl r12, File_GetLength
  stw r3, OFST_SIZE(REG_DATA) # store to gobj data

  mr r3, REG_NAME
  lwz r4, OFST_BUF(REG_DATA)
  addi r5, REG_DATA, OFST_SIZE
  branchl r12, File_Read # File_Read wont return until the file is loaded

  li r3, 0
  li r4, SZ_ARCHIVE
  branchl r12, HSD_MemAllocFromHeap # allocate space for the archive
  mr REG_ARCHIVE, r3

  mr r3, REG_ARCHIVE
  lwz r4, OFST_BUF(REG_DATA)
  lwz r5, OFST_SIZE(REG_DATA)
  branchl r12, Archive_InitDat

  mr r3, REG_ARCHIVE
  load r4, 0x803e0768 # "map_head"
  branchl r12, Archive_GetSymbol
  mr REG_MHEAD, r3

  branchl r12, 0x801C62B4 # gets the correct offset for storing to stage data?
  mr REG_MDATA, r3

  stw REG_ARCHIVE, OFST_BASE(REG_MDATA)
  stw REG_MHEAD, OFST_HEAD(REG_MDATA)
  li r3, 1
  stw r3, OFST_UNKX14(REG_MDATA)

# store archive offset to gobj data
  addi r3, REG_MDATA, OFST_BASE
  stw r3, 0xD0(REG_DATA)

  addi r3, REG_MDATA, OFST_HEAD
  branchl r12, 0x801C6228 # ???


EXIT:
  restore
  branch r12, 0x80016678 # skip the rest of the function