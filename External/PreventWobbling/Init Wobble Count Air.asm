################################################################################
# Address: 800db880
# Tags: [affects-gameplay]
################################################################################
.include "External/PreventWobbling/PreventWobbling.s"

Wobbling_InitWobbleCount

#Original codeline
lwz	r0, 0x005C (sp)
