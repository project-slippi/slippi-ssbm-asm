################################################################################
# Address: 0x800d4c1c
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# orig instruction
  stw	r0, 0x2344 (r31)

# init custom velocity
  lfs	f0, 0x0030 (r30)  # y velocity
  stfs f0, 0x2348 (r31)
  lfs	f0, 0x003C (r30)  # z velocity
  stfs f0, 0x234C (r31)

# zero original velocity
  li r3,0
  stw r3, 0x80 (r31)
  stw r3, 0x84 (r31)
  stw r3, 0x88 (r31)

Exit:
