################################################################################
# Address: 0x803a63a8 # Address in Text_CopyPremadeTextDataToStruct where value
# in r0 is stored to pointer where SisMenuData with encoded String format is
# read from.
# This is supposed patch the original function to read r6 and r7 to determine if
# we should read from dolphin or continue as is
# OFST_R13_USE_PREMADE_TEXT must be set to 1 before calling this method
# r6 must be set to an specific constant maybe 0x01020304
# r7 is the actual id of the text we want to read, a map on dolphin like
# 0x1 = "<KERN><CENTER><COLOR, 170, 170, 170><TEXTBOX, 179, 179><UNK06, 0, 0><FIT>Solo<S>Smash!</FIT></TEXTBOX></COLOR><END>"
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_STRING_FORMAT_ADDR, 30
.set REG_PREMADE_TEXT_ID, REG_STRING_FORMAT_ADDR-1

backup
mr REG_PREMADE_TEXT_ID, r6

# So, what we are going to do here is request a READ from the EXI device which
# will return the encoded string requested with an ID and then store that into
# the text data struct
lbz r3, OFST_R13_USE_PREMADE_TEXT(r13)
cmpwi r3, 1
bne EXIT # get out if this is just the game doing it's thing

# Load Premade text id from dolphin
mr r3, REG_PREMADE_TEXT_ID
branchl r12, FN_LoadPremadeText
mr REG_STRING_FORMAT_ADDR, r3
stw REG_STRING_FORMAT_ADDR, 0x5C(r31)

EXIT:
restore
# stw	r0, 0x005C (r31) # original line before this one
li	r3, 0 # original line
stb r3, OFST_R13_USE_PREMADE_TEXT(r13) # clear out r13 offset

#############################
# Original Func: Text_CopyPremadeTextDataToStruct
#; 803a6368: mflr	r0
#; 803a636c: stw	r0, 0x0004 (sp)
#; 803a6370: stwu	sp, -0x0018 (sp)
#; 803a6374: stw	r31, 0x0014 (sp)
#; 803a6378: mr	r31, r3
#; 803a637c: lbz	r5, 0x004F (r3)
#; 803a6380: lis	r3, 0x804D
#; 803a6384: addi	r0, r3, 4388
#; 803a6388: rlwinm	r3, r5, 2, 0, 29 (3fffffff)
#; 803a638c: add	r3, r0, r3
#; 803a6390: lwz	r3, 0 (r3)
#; 803a6394: cmplwi	r3, 0
#; 803a6398: beq-	 ->0x803A63A8
#; 803a639c: rlwinm	r0, r4, 2, 0, 29 (3fffffff)
#; 803a63a0: lwzx	r0, r3, r0
#; 803a63a4: stw	r0, 0x005C (r31)
#; 803a63a8: li	r3, 0
#; 803a63ac: stw	r3, 0x0060 (r31)
#; 803a63b0: lfs	f0, -0x0F38 (rtoc)
#; 803a63b4: stfs	f0, 0x0074 (r31)
#; 803a63b8: stfs	f0, 0x0070 (r31)
#; 803a63bc: lwz	r0, 0x0030 (r31)
#; 803a63c0: stw	r0, 0x008C (r31)
#; 803a63c4: lfs	f0, 0x0034 (r31)
#; 803a63c8: stfs	f0, 0x0080 (r31)
#; 803a63cc: lfs	f0, 0x0038 (r31)
#; 803a63d0: stfs	f0, 0x0084 (r31)
#; 803a63d4: lfs	f0, 0x003C (r31)
#; 803a63d8: stfs	f0, 0x0078 (r31)
#; 803a63dc: lfs	f0, 0x0040 (r31)
#; 803a63e0: stfs	f0, 0x007C (r31)
#; 803a63e4: lhz	r0, 0x0044 (r31)
#; 803a63e8: sth	r0, 0x0090 (r31)
#; 803a63ec: lhz	r0, 0x0046 (r31)
#; 803a63f0: sth	r0, 0x0092 (r31)
#; 803a63f4: lbz	r0, 0x004A (r31)
#; 803a63f8: stb	r0, 0x009E (r31)
#; 803a63fc: lbz	r0, 0x0049 (r31)
#; 803a6400: stb	r0, 0x009D (r31)
#; 803a6404: lbz	r0, 0x0048 (r31)
#; 803a6408: stb	r0, 0x009C (r31)
#; 803a640c: sth	r3, 0x006C (r31)
#; 803a6410: stw	r3, 0x0098 (r31)
#; 803a6414: stw	r3, 0x0094 (r31)
#; 803a6418: stb	r3, 0x004B (r31)
#; 803a641c: lwz	r3, 0x0068 (r31)
#; 803a6420: cmplwi	r3, 0
#; 803a6424: beq-	 ->0x803A642C
#; 803a6428: bl	->0x803A594C
#; 803a642c: li	r3, 16
#; 803a6430: bl	->0x803A5798
#; 803a6434: stw	r3, 0x0068 (r31)
#; 803a6438: li	r0, 16
#; 803a643c: li	r5, 0
#; 803a6440: sth	r0, 0x006E (r31)
#; 803a6444: li	r4, 0
#; 803a6448: b	->0x803A6458
#; 803a644c: lwz	r3, 0x0068 (r31)
#; 803a6450: stbx	r4, r3, r5
#; 803a6454: addi	r5, r5, 1
#; 803a6458: lhz	r0, 0x006E (r31)
#; 803a645c: cmpw	r5, r0
#; 803a6460: blt+	 ->0x803A644C
#; 803a6464: lwz	r0, 0x001C (sp)
#; 803a6468: lwz	r31, 0x0014 (sp)
#; 803a646c: addi	sp, sp, 24
#; 803a6470: mtlr	r0
#; 803a6474: blr
