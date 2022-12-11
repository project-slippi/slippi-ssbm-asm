################################################################################
# Address: 8008F090
# Tags: [affects-gameplay]
################################################################################
.include "External/PreventWobbling/PreventWobbling.s"

Wobbling_Check

# Original codeline
lwz	r0, 0x0010 (r27)