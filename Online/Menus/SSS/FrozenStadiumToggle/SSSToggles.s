.ifndef HEADER_SSS_TOGGLES
################################################################################
# Functions
################################################################################
.set JOBJ_GetDobj, 0x80371bec
.set JOBJ_AddConstraintPos, 0x8000c1c0
.set SSS_CreateStageNameText, 0x80259ed8

################################################################################
# Structs
################################################################################


################################################################################
# Directives
################################################################################
.set MnSlMapModels, 0x804d6c98 # (*StaticModeDesc[12 + WarCmnTop])
.set SSS_IconData, 0x803f06d0
.set SSS_HoveredIcon, 0x804d6cae # u8
.set GOBJ_Current, 0x804d781c
.set SSS_CustomData, 0x804a2f48 # some unk exit data, should be unused and unreachable in emulation
.set HSD_PadMaster, 0x804c1fac

.set ID_GRPS, 18
.set SZ_ICON, 28
.set OFST_HOVERED_ICON, -0x49F2

.endif
