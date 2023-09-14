################################################################################
# Address: 0x80394a68
################################################################################

.include "Common/Common.s"
.include "Debugging/AdditionalCrashInfo/AdditionalCrashInfoStatic.s"

b CODE_START

STATIC_MEMORY_TABLE_BLRL:
blrl
createAdditionalCrashInfoStaticMem

FN_PRINT_STR_AT_OFFSET:
backup

# Get string to print, save to r3
mr r31, r3
bl STATIC_MEMORY_TABLE_BLRL
mflr r3
add r3, r3, r31

# Call OSReport function, r4+ and f1+ args should have been set by caller
branchl r12, OSReport

restore
blr

CODE_START:
addi r27, r4, 0 # replaced code line

li r3, ACISMO_NEW_LINE_CHAR_STR
bl FN_PRINT_STR_AT_OFFSET
li r3, ACISMO_VERSION_STR
bl FN_PRINT_STR_AT_OFFSET
li r3, ACISMO_NEW_LINE_CHAR_STR
bl FN_PRINT_STR_AT_OFFSET
li r3, ACISMO_CONSOLE_RUNTIME_STR
loadwz r4, 0x804d7420 # Console runtime frame count
bl FN_PRINT_STR_AT_OFFSET
li r3, ACISMO_SCENE_RUNTIME_STR
loadGlobalFrame r4 # Scene runtime frame count
bl FN_PRINT_STR_AT_OFFSET
li r3, ACISMO_NEW_LINE_CHAR_STR
bl FN_PRINT_STR_AT_OFFSET

EXIT: