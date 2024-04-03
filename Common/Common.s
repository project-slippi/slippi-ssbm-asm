.ifndef HEADER_COMMON

################################################################################
# Macros
################################################################################
.macro branchl reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctrl
.endm

.macro branch reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctr
.endm

.macro load reg, address
lis \reg, \address @h
ori \reg, \reg, \address @l
.endm

.macro loadwz reg, address
lis \reg, \address @h
ori \reg, \reg, \address @l
lwz \reg, 0(\reg)
.endm

.macro loadbz reg, address
lis \reg, \address @h
ori \reg, \reg, \address @l
lbz \reg, 0(\reg)
.endm

.macro incrementByteInBuf reg, reg_address, offset, limit
lbz \reg, \offset(\reg_address)
addi \reg, \reg, 1
cmpwi \reg, \limit
blt 0f
li \reg, 0
0:
stb \reg, \offset(\reg_address)
.endm

# Compiled from the following:
# int func(int current, int change, int limit) {
#     return (((current + change) % limit) + limit) % limit;
# }
.macro adjustCircularIndex reg, reg_current, reg_change, reg_limit, reg_temp=r0
add \reg, \reg_current, \reg_change
divw \reg_temp, \reg, \reg_limit
mullw \reg_temp, \reg_temp, \reg_limit
subf \reg_temp, \reg_temp, \reg
add \reg, \reg_limit, \reg_temp
divw \reg_temp, \reg, \reg_limit
mullw \reg_temp, \reg_temp, \reg_limit
subf \reg, \reg_temp, \reg
.endm

.macro bp
branchl r12, 0x8021b2d8
.endm

# This is where the free space in our stack frame starts
.set BKP_FREE_SPACE_OFFSET, 8

# The default free space such that we don't break any legacy codes, includes the location where
# the non-volatile registers were stored as well as the 0x78 of free space that used to exist.
# Now it's all just free space
.set BKP_DEFAULT_FREE_SPACE_SIZE, 0xA8
.set BKP_DEFAULT_FREG, 0
.set BKP_DEFAULT_REG, 12

# backup is used to set up a stack frame in which LR and non-volatile registers will be stored.
# It also sets up some free space on the stack for the function to use if needed.
# More info: https://docs.google.com/document/d/1QJOQzy933fxpfzIJlq6xopcviZ5tALKQvi_OOqpjehE
.macro backup free_space=BKP_DEFAULT_FREE_SPACE_SIZE, num_freg=BKP_DEFAULT_FREG, num_reg=BKP_DEFAULT_REG
mflr r0
stw r0, 0x4(r1)
# Stack allocation has to be 4-byte aligned otherwise it crashes on console. This section
# makes space for the back chain, LR, non-volatile registers, and free space
.if \free_space % 4 == 0
  .set ALIGNED_FREE_SPACE, \free_space
.else
  .set ALIGNED_FREE_SPACE, \free_space + (4 - \free_space % 4)
.endif
stwu r1,-(0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * \num_freg)(r1)
.if \num_reg > 0
  stmw 32 - \num_reg, (0x8 + ALIGNED_FREE_SPACE)(r1)
.endif
.if \num_freg > 0
  stfd f31, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 0)(r1)
.endif
.if \num_freg > 1
  stfd f30, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 1)(r1)
.endif
.if \num_freg > 2
  stfd f29, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 2)(r1)
.endif
.if \num_freg > 3
  stfd f28, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 3)(r1)
.endif
.if \num_freg > 4
  stfd f27, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 4)(r1)
.endif
.if \num_freg > 5
  stfd f26, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 5)(r1)
.endif
.if \num_freg > 6
  stfd f25, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 6)(r1)
.endif
.if \num_freg > 7
  stfd f24, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 7)(r1)
.endif
.if \num_freg > 8
  stfd f23, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 8)(r1)
.endif
.if \num_freg > 9
  stfd f22, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 9)(r1)
.endif
.if \num_freg > 10
  stfd f21, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 10)(r1)
.endif
.if \num_freg > 11
  stfd f20, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 11)(r1)
.endif
.if \num_freg > 12
  stfd f19, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 12)(r1)
.endif
.if \num_freg > 13
  stfd f18, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 13)(r1)
.endif
.if \num_freg > 14
  stfd f17, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 14)(r1)
.endif
.if \num_freg > 15
  stfd f16, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 15)(r1)
.endif
.if \num_freg > 16
  stfd f15, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 16)(r1)
.endif
.if \num_freg > 17
  stfd f14, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 17)(r1)
.endif
.endm

.macro restore free_space=BKP_DEFAULT_FREE_SPACE_SIZE, num_freg=BKP_DEFAULT_FREG, num_reg=BKP_DEFAULT_REG
# Stack allocation has to be 4-byte aligned otherwise it crashes on console
.if \free_space % 4 == 0
  .set ALIGNED_FREE_SPACE, \free_space
.else
  .set ALIGNED_FREE_SPACE, \free_space + (4 - \free_space % 4)
.endif
.if \num_reg > 0
  lmw 32 - \num_reg, (0x8 + ALIGNED_FREE_SPACE)(r1)
.endif
.if \num_freg > 0
  lfd f31, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 0)(r1)
.endif
.if \num_freg > 1
  lfd f30, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 1)(r1)
.endif
.if \num_freg > 2
  lfd f29, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 2)(r1)
.endif
.if \num_freg > 3
  lfd f28, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 3)(r1)
.endif
.if \num_freg > 4
  lfd f27, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 4)(r1)
.endif
.if \num_freg > 5
  lfd f26, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 5)(r1)
.endif
.if \num_freg > 6
  lfd f25, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 6)(r1)
.endif
.if \num_freg > 7
  lfd f24, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 7)(r1)
.endif
.if \num_freg > 8
  lfd f23, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 8)(r1)
.endif
.if \num_freg > 9
  lfd f22, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 9)(r1)
.endif
.if \num_freg > 10
  lfd f21, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 10)(r1)
.endif
.if \num_freg > 11
  lfd f20, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 11)(r1)
.endif
.if \num_freg > 12
  lfd f19, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 12)(r1)
.endif
.if \num_freg > 13
  lfd f18, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 13)(r1)
.endif
.if \num_freg > 14
  lfd f17, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 14)(r1)
.endif
.if \num_freg > 15
  lfd f16, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 15)(r1)
.endif
.if \num_freg > 16
  lfd f15, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 16)(r1)
.endif
.if \num_freg > 17
  lfd f14, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * 17)(r1)
.endif
lwz r0, (0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * \num_freg + 0x4)(r1)
addi r1, r1, 0x8 + ALIGNED_FREE_SPACE + 0x4 * \num_reg + 0x8 * \num_freg	# release the space
mtlr r0
.endm

.macro byteAlign32 reg
addi \reg, \reg, 31
rlwinm \reg, \reg, 0, 0xFFFFFFE0
.endm

.macro backupall
mflr r0
stw r0, 0x4(r1)
stwu r1,-0x100(r1)
stmw r3,0x8(r1)
.endm

.macro restoreall
lmw r3,0x8(r1)
lwz r0, 0x104(r1)
addi r1,r1,0x100
mtlr r0
.endm

.macro logf level, str, arg1="nop", arg2="nop", arg3="nop", arg4="nop", arg5="nop", arg6="nop"
b 1f
0:
blrl
.string "\str"
.align 2

1:
backupall

# Set up args to log
\arg1
\arg2
\arg3
\arg4
\arg5
\arg6

lwz r3, OFST_R13_SB_ADDR(r13) # Buf to use as EXI buf
addi r3, r3, 3
bl 0b
mflr r4
crset 6
branchl r12, 0x80323cf4 # sprintf

lwz r3, OFST_R13_SB_ADDR(r13) # Buf to use as EXI buf

li r4, 0xD0
stb r4, 0(r3)
li r4, 0 # Do not request time to be logged
stb r4, 1(r3)
li r4, \level
stb r4, 2(r3)

li r4, 128 # Length of buf
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

restoreall
.endm

.macro oslogf str, arg1="nop", arg2="nop", arg3="nop", arg4="nop", arg5="nop"
b 1f
0:
blrl
.string "\str"
.align 2

1:
backupall

# Set up args to log
\arg1
\arg2
\arg3
\arg4
\arg5

# Call OSReport
bl 0b
mflr r3
branchl r12, 0x803456a8 # OSReport

restoreall
.endm

.macro getMinorMajor reg
lis \reg, 0x8048 # load address to offset from for scene controller
lwz \reg, -0x62D0(\reg) # Load from 0x80479D30 (scene controller)
rlwinm \reg, \reg, 8, 0xFFFF # Loads major and minor scene into bottom of reg
.endm

.macro getMajorId reg
lis \reg, 0x8048 # load address to offset from for scene controller
lbz \reg, -0x62D0(\reg) # Load byte from 0x80479D30 (major ID)
.endm

.macro loadGlobalFrame reg
lis \reg, 0x8048
lwz \reg, -0x62A0(\reg) # 80479D60
.endm

# This macro takes in an address that is expected to have a branch instruction. It will set
# r3 to the address being branched to. This will overwrite r3 and r4
.macro computeBranchTargetAddress reg address
load r3, \address
lwz r4, 0(r3) # Get branch instruction which contains offset

# This extracts the LI portion of the branch instruction and shifts it such
# that the sign bit is all the way left. Then it does a divide instruction to
# shift to the right 6 bits while preserving the sign. After that, add to
# branch instruction location to get result.
# Credit to taukhan for the divw improvement (saves 2 instructions)
rlwinm r5, r4, 6, 0xFFFFFF00
li r4, 64
divw r4, r5, r4
add \reg, r3, r4
.endm

################################################################################
# Settings
################################################################################
# STG_EXIIndex is now set during build with arg -defsym STG_EXIIndex=1
#.set STG_EXIIndex, 1 # 0 is SlotA, 1 is SlotB. Indicates which slot to use

.set STG_DesyncDebug, 0 # Prod: 0 | Debug flag for OSReporting desyncs

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_EXITransferBuffer,0x800055f0
.set FN_GetIsFollower,0x800055f8
.set FN_ProcessGecko,0x800055fc
.set FN_MultiplyRWithF,0x800055ec
.set FN_IntToFloat,0x800055f4
.set FG_CreateSubtext,0x800056b4
.set FN_GetTeamCostumeIndex,0x800056b0
.set FN_GetCSSIconData,0x800056b8
.set FN_AdjustNullID,0x80005694
.set FN_CheckAltStageName,0x80005690
.set FN_GetCSSIconNum,0x80005698
.set FN_LoadPremadeText, 0x800056a4
.set FN_GetSSMIndex,0x800056a0
.set FN_GetFighterNum,0x8000569c
.set FN_CSSUpdateCSP,0x800056bc
.set FN_RequestSSM,0x800056a8
.set FN_GetCommonMinorID,0x8000561c
# available addresses for static functions
# 0x8000568C

# Online static functions
.set FN_CaptureSavestate,0x80005608
.set FN_LoadSavestate,0x8000560C
.set FN_LoadMatchState,0x80005610
.set FG_UserDisplay,0x80005618

# The rest of these are NTSC v1.02 functions
## HSD functions
.set HSD_Randi,0x80380580
.set HSD_MemAlloc,0x8037f1e4
.set HSD_Free,0x8037f1b0
.set HSD_PadFlushQueue,0x80376d04
.set HSD_StartRender,0x80375538
.set HSD_VICopyXFBASync,0x803761c0
.set HSD_PerfSetStartTime,0x8037E214
.set HSD_PadRumbleActiveID,0x80378430
.set HSD_ArchiveGetPublicAddress, 0x80380358

## GObj functions
.set GObj_Create,0x803901f0 #(obj_type,subclass,priority)
.set GObj_AddUserData,0x80390b68 #void (*GObj_AddUserData)(GOBJ *gobj, int userDataKind, void *destructor, void *userData) = (void *)0x80390b68;
.set GObj_Destroy,0x80390228
.set GObj_AddProc,0x8038fd54 # (obj,func,priority)
.set GObj_RemoveProc,0x8038fed4
.set GObj_AddToObj,0x80390A70 #(gboj,obj_kind,obj_ptr)
.set GObj_SetupGXLink, 0x8039069c #(gobj,function,gx_link,priority)

## AObj Functions
.set AObj_SetEndFrame, 0x8036532C #(aobj, frame)

## JObj Functions
.set JObj_GetJObjChild,0x80011e24
.set JObj_RemoveAnimAll,0x8036f6b4
.set JObj_LoadJoint, 0x80370E44 #(jobj_desc_ptr)
.set JObj_AddAnim, 0x8036FA10 # (jobj,an_joint,mat_joint,sh_joint)
.set JObj_AddAnimAll, 0x8036FB5C # (jobj,an_joint,mat_joint,sh_joint)
.set JObj_ReqAnim, 0x8036F934 #(HSD_JObj* jobj, f32 frame)
.set JObj_ReqAnimAll, 0x8036F8BC #(HSD_JObj* jobj, f32 frame)
.set JObj_Anim, 0x80370780 #(jobj)
.set JObj_AnimAll, 0x80370928 #(jobj)
.set JObj_ClearFlags, 0x80371f00 #(jobj,flags)
.set JObj_ClearFlagsAll, 0x80371F9C #(jobj,flags)
.set JObj_SetFlags, 0x80371D00 # (jobj,flags)
.set JObj_SetFlagsAll, 0x80371D9c # (jobj,flags)

## Text functions
.set Text_AllocateMenuTextMemory,0x803A5798
.set Text_FreeMenuTextMemory,0x80390228 # Not sure about this one, but it has a similar behavior to the Allocate
.set Text_CreateStruct,0x803a6754
.set Text_AllocateTextObject,0x803a5acc
.set Text_CopyPremadeTextDataToStruct,0x803a6368# (text struct, index on open menu file, cannot be used, jackpot=will change to memory address we want)
.set Text_InitializeSubtext,0x803a6b98
.set Text_UpdateSubtextSize,0x803a7548
.set Text_ChangeTextColor,0x803a74f0
.set Text_DrawEachFrame,0x803a84bc
.set Text_UpdateSubtextContents,0x803a70a0
.set Text_RemoveText,0x803a5cc4

## EXI functions
.set EXIAttach,0x803464c0
.set EXILock,0x80346d80
.set EXISelect,0x80346688
.set EXIDma,0x80345e60
.set EXISync,0x80345f4c
.set EXIDeselect,0x803467b4
.set EXIUnlock,0x80346e74
.set EXIDetach,0x803465cc

## Nametag data functions
.set Nametag_LoadSlotText,0x8023754c
.set Nametag_SetNameAsInUse,0x80237a04
.set Nametag_GetNametagBlock,0x8015cc9c

## VI/GX functions
.set GXInvalidateVtxCache,0x8033c898
.set GXInvalidateTexAll,0x8033f270
.set VIWaitForRetrace,0x8034f314
.set VISetBlack,0x80350100

.set OSDisableInterrupts, 0x80347364
.set OSRestoreInterrupts, 0x8034738c
.set OSCancelAlarm, 0x80343aac
.set InsertAlarm, 0x80343778

## Common/memory management
.set va_arg, 0x80322620
.set OSReport,0x803456a8
.set memcpy,0x800031f4
.set memcmp,0x803238c8
.set strcpy,0x80325a50
.set strlen,0x80325b04
.set sprintf,0x80323cf4
.set Zero_AreaLength,0x8000c160
.set TRK_flush_cache,0x80328f50
.set FileLoad_ToPreAllocatedSpace,0x80016580
.set DiscError_ResumeGame,0x80024f6c

## PlayerBlock/game-state related functions
.set PlayerBlock_LoadStaticBlock,0x80031724
.set PlayerBlock_UpdateCoords,0x80032828
.set PlayerBlock_LoadExternalCharID,0x80032330
.set PlayerBlock_LoadRemainingStocks,0x80033bd8
.set PlayerBlock_LoadSlotType,0x8003241c
.set PlayerBlock_LoadDataOffsetStart,0x8003418c
.set PlayerBlock_LoadTeamID,0x80033370
.set PlayerBlock_StoreInitialCoords,0x80032768
.set PlayerBlock_LoadPlayerXPosition,0x800326cc
.set PlayerBlock_UpdateFacingDirection,0x80033094
.set PlayerBlock_LoadMainCharDataOffset,0x80034110
.set SpawnPoint_GetXYZFromSpawnID,0x80224e64
.set Damage_UpdatePercent,0x8006cc7c
.set MatchEnd_GetWinningTeam,0x801654a0

## Camera functions
.set Camera_UpdatePlayerCameraBox,0x800761c8
.set Camera_CorrectPosition,0x8002f3ac

## Audio/SFX functions
.set SFX_StopSFXInstance, 0x800236b8
.set Audio_AdjustMusicSFXVolume,0x80025064
.set SFX_Menu_CommonSound,0x80024030
.set SFX_PlaySoundAtFullVolume, 0x800237a8 #SFX_PlaySoundAtFullVolume(r3=soundid,r4=volume?,r5=priority)

## Scene/input-related functions
.set NoContestOrRetry_,0x8016cf4c
.set fetchAnimationHeader,0x80085fd4
.set Damage_UpdatePercent,0x8006cc7c
.set Obj_ChangeRotation_Yaw,0x8007592c
.set MenuController_ChangeScreenMinor,0x801a4b60
.set SinglePlayerModeCheck,0x8016b41c
.set CheckIfGameEnginePaused,0x801a45e8
.set Inputs_GetPlayerHeldInputs,0x801a3680
.set Inputs_GetPlayerInstantInputs,0x801A36A0
.set Rumble_StoreRumbleFlag,0x8015ed4c
.set Audio_AdjustMusicSFXVolume,0x80025064
.set DiscError_ResumeGame,0x80024f6c
.set RenewInputs_Prefunction,0x800195fc
.set PadAlarmCheck,0x80019894
.set Event_StoreSceneNumber,0x80229860
.set EventMatch_Store,0x801beb74
.set PadRead,0x8034da00

## Miscellenia/Unsorted
.set fetchAnimationHeader,0x80085fd4
.set Obj_ChangeRotation_Yaw,0x8007592c
.set Character_GetMaxCostumeCount,0x80169238


################################################################################
# Const Definitions
################################################################################
# For EXI transfers
.set CONST_ExiRead, 0 # arg value to make an EXI read
.set CONST_ExiWrite, 1 # arg value to make an EXI write

# For Slippi communication
.set CONST_SlippiCmdGetFrame, 0x76
.set CONST_SlippiCmdCheckForReplay, 0x88
.set CONST_SlippiCmdCheckForStockSteal,0x89
.set CONST_SlippiCmdSendOnlineFrame,0xB0
.set CONST_SlippiCmdCaptureSavestate,0xB1
.set CONST_SlippiCmdLoadSavestate,0xB2
.set CONST_SlippiCmdGetMatchState,0xB3
.set CONST_SlippiCmdFindOpponent,0xB4
.set CONST_SlippiCmdSetMatchSelections,0xB5
.set CONST_SlippiCmdOpenLogIn,0xB6
.set CONST_SlippiCmdLogOut,0xB7
.set CONST_SlippiCmdUpdateApp,0xB8
.set CONST_SlippiCmdGetOnlineStatus,0xB9
.set CONST_SlippiCmdCleanupConnections,0xBA
.set CONST_SlippiCmdSendChatMessage,0xBB
.set CONST_SlippiCmdGetNewSeed,0xBC
.set CONST_SlippiCmdReportMatch,0xBD
.set CONST_SlippiCmdSendNameEntryIndex,0xBE
.set CONST_SlippiCmdNameEntryAutoComplete,0xBF
.set CONST_SlippiCmdReportSetCompletion,0xC2
# For Slippi file loads
.set CONST_SlippiCmdFileLength, 0xD1
.set CONST_SlippiCmdFileLoad, 0xD2
.set CONST_SlippiCmdGctLength, 0xD3
.set CONST_SlippiCmdGctLoad, 0xD4

# Misc
.set CONST_SlippiCmdGetDelay, 0xD5
.set CONST_SlippiPlayMusic, 0xD6
.set CONST_SlippiStopMusic, 0xD7
.set CONST_SlippiChangeMusicVolume, 0xD8

# For Slippi Premade Texts
.set CONST_SlippiCmdGetPremadeTextLength, 0xE1
.set CONST_SlippiCmdGetPremadeText, 0xE2
.set CONST_TextDolphin, 0x765 # Flag identifying that Text_CopyPremadeTextDataToStruct needs to load from dolphin

.set CONST_FirstFrameIdx, -123

.set RtocAddress, 0x804df9e0

.set ControllerFixOptions,0xDD8 # Each byte at offset is a player's setting
.set UCFTextPointers,0x4fa0

.set DashbackOptions,0xDD4 # Offset for dashback-specific settings (playback)
.set ShieldDropOptions,0xDD0 # Offset for shielddrop-specific settings (playback)

.set PALToggle,-0xDCC   #offset for whether or not the replay is played with PAL modifications
.set PSPreloadToggle,-0xDC8   #offset for whether or not the replay is played with PS Preload Behavior
.set FSToggle,-0xDC4    #offset for whether or not the replay is played with the Frozen PS toggle
.set HideWaitingForGame,-0xDC0   #offset for whether or not to display the waiting for game text

.set PALToggleAddr, RtocAddress + PALToggle
.set PSPreloadToggleAddr, RtocAddress + PSPreloadToggle
.set FSToggleAddr, RtocAddress + FSToggle
.set HideWaitingForGameAddress, RtocAddress + HideWaitingForGame
.set CFOptionsAddress, RtocAddress - ControllerFixOptions
.set GeckoHeapPtr, 0x80005600

# Internal scenes
.set SCENE_TRAINING_CSS, 0x001C
.set SCENE_TRAINING_SSS, 0x011C
.set SCENE_TRAINING_IN_GAME, 0x021C

.set SCENE_VERSUS_CSS, 0x0002
.set SCENE_VERSUS_SSS, 0x0102
.set SCENE_VERSUS_IN_GAME, 0x0202
.set SCENE_VERSUS_SUDDEN_DEATH, 0x0302

.set SCENE_TARGETS_CSS, 0x000F
.set SCENE_TARGETS_IN_GAME, 0x010F

.set SCENE_HOMERUN_CSS, 0x0020
.set SCENE_HOMERUN_IN_GAME, 0x0120

# Playback scene
.set SCENE_PLAYBACK_IN_GAME, 0x010E

################################################################################
# Offsets from r13
################################################################################
.set primaryDataBuffer,-0x49b4
.set playbackDataBuffer,-0x5040 # From tournament mode line 8019b9d4, seems to be only used in one place
.set secondaryDmaBuffer,-0x49b0
.set archiveDataBuffer, -0x4AE8
.set bufferOffset,-0x49b0
.set frameIndex,-0x49ac
.set textStructDescriptorBuffer,-0x3D24
.set isWidescreen,-0x5020
.set OFST_R13_SB_ADDR,-0x503C # Scene buffer, persists throughout scenes

################################################################################
# Log levels
################################################################################
.set LOG_LEVEL_INFO, 4
.set LOG_LEVEL_WARN, 3
.set LOG_LEVEL_ERROR, 2
.set LOG_LEVEL_NOTICE, 1

.endif
.set HEADER_COMMON, 1
