#To be inserted at 0x8016e9b4
b SETUP

.include "Common/Common.s"
.include "Common/Controller Overlay/constants.asm"
.include "Common/Controller Overlay/utils.asm"
.include "Common/Controller Overlay/data.asm"
.include "Common/Controller Overlay/callback.asm"
.include "Common/Controller Overlay/setup.asm"

EXIT:
# replaced instruction
lwz	r0, 0x001C (sp)
