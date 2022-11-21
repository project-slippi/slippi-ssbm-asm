.ifndef HEADER_ADDITIONAL_CRASH_INFO_STATIC

# Define additional crash info static mem offsets, these must be synced with the static mem
# defined below
.set ACISMO_VERSION_STR, 0 # char[64]
.set ACISMO_CONSOLE_RUNTIME_STR, ACISMO_VERSION_STR + 64 # char[29]
.set ACISMO_SCENE_RUNTIME_STR, ACISMO_CONSOLE_RUNTIME_STR + 29 # char[27]
.set ACISMO_NEW_LINE_CHAR_STR, ACISMO_SCENE_RUNTIME_STR + 27 # char[2]

.macro createAdditionalCrashInfoStaticMem
# The string below should be overwritten by the application to provide correct version
# IMPORTANT: The version string should ALWAYS be first
.string "Placeholder for Version and Application: v00.00.00-000-00000000"
.string " Console runtime: %d frames\n"
.string " Scene runtime: %d frames\n"
.string "\n"

.align 2
.endm

.endif
.set HEADER_ADDITIONAL_CRASH_INFO_STATIC, 1
