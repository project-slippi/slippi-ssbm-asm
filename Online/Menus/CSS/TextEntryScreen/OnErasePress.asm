################################################################################
# Address: 0x8023c81c
################################################################################

.include "Common/Common.s"

# Pressing A on the erase button works very similar to pressing B except that the last char erase
# doesn't return to CSS, instead it plays an error sound.

# TODO: For now make this behave like the B button, nobody uses this button anyway.
branch r12, 0x8023cd3c