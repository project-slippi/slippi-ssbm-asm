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

.macro loadf regf,reg,address
lis \reg, \address @h
ori \reg, \reg, \address @l
stw \reg,-0x4(sp)
lfs \regf,-0x4(sp)
.endm

.macro backup
mflr r0
stw r0, 0x4(r1)
stwu r1,-0xB0(r1)	# make space for 12 registers
stmw r20,0x8(r1)
.endm

 .macro restore
lmw r20,0x8(r1)
lwz r0, 0xB4(r1)
addi r1,r1,0xB0	# release the space
mtlr r0
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

.macro getMinorMajor reg
lis \reg, 0x8048 # load address to offset from for scene controller
lwz \reg, -0x62D0(\reg) # Load from 0x80479D30 (scene controller)
rlwinm \reg, \reg, 8, 0xFFFF # Loads major and minor scene into bottom of reg
.endm

################################################################################
# Settings
################################################################################
# STG_EXIIndex is now set during build with arg -defsym STG_EXIIndex=1
#.set STG_EXIIndex, 1 # 0 is SlotA, 1 is SlotB. Indicates which slot to use

.set STG_DesyncDebug, 0 # Debug flag for OSReporting desyncs

################################################################################
# Static Function Locations
################################################################################
# Local functions (added by us)
.set FN_EXITransferBuffer,0x800055f0
.set FN_GetIsFollower,0x800055f8
.set FN_ProcessGecko,0x800055fc

# The rest of these are NTSC v1.02 functions
## HSD functions
.set HSD_Randi,0x80380580
.set HSD_MemAlloc,0x8037f1e4
.set HSD_Free,0x8037f1b0
.set HSD_PadFlushQueue,0x80376d04
.set HSD_StartRender,0x80375538
.set HSD_VICopyXFBASync,0x803761c0
.set HSD_PadRumbleActiveID,0x80378430

## GObj functions
.set GObj_Create,0x803901f0
.set GObj_Initialize,0x80390b68
.set GObj_Destroy,0x80390228
.set GObj_AddProc,0x8038fd54
.set GObj_RemoveProc,0x8038fed4

## Text functions
.set Text_CreateStruct,0x803a6754
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

## Common/memory management
.set OSReport,0x803456a8
.set memcpy,0x800031f4
.set strcpy,0x80325a50
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
.set Audio_AdjustMusicSFXVolume,0x80025064
.set SFX_Menu_CommonSound,0x80024030

## Scene/input-related functions
.set MenuController_ChangeScreenMinor,0x801a4b60
.set SinglePlayerModeCheck,0x8016b41c
.set CheckIfGameEnginePaused,0x801a45e8
.set Inputs_GetPlayerHeldInputs,0x801a3680
.set Rumble_StoreRumbleFlag,0x8015ed4c

## Miscellenia/Unsorted
.set fetchAnimationHeader,0x80085fd4
.set Obj_ChangeRotation_Yaw,0x8007592c
.set NoContestOrRetry_,0x8016cf4c
.set Character_GetMaxCostumeCount,0x80169238


################################################################################
# Const Definitions
################################################################################
# For EXI transfers
.set CONST_ExiRead, 0 # arg value to make an EXI read
.set CONST_ExiWrite, 1 # arg value to make an EXI write

.set GeckoCodeSectionStart,0x801910E8

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

################################################################################
# Offsets
################################################################################
.set primaryDataBuffer,-0x49b4
.set bufferOffset,-0x49b0
.set frameIndex,-0x49ac
