#To be inserted at 8006b5f8
.include "../../Common/Common.s"
.include "../Recording.s"

# Store previous button timer
  lbz	r3, 0x0682 (r31)
  stb r3, DPadDownTimer(r31)
