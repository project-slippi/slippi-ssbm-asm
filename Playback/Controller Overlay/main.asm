#To be inserted at 0x8016e9b4
b SETUP

.include "Common/Common.s"
.include "Playback/Controller Overlay/constants.asm"
.include "Playback/Controller Overlay/utils.asm"
.include "Playback/Controller Overlay/data.asm"
.include "Playback/Controller Overlay/callback.asm"
.include "Playback/Controller Overlay/setup.asm"

EXIT:
# replaced instruction
lwz	r0, 0x001C (sp)
