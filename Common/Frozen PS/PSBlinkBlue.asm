# Insert at 80259ef8
.include "../Common.s"

.set ADDR_COLOR_BASE, 0x80c4bca8
.set OFST_RFILL_PRIMARY, 0x1
.set OFST_BFILL_PRIMARY, 0x15
.set OFST_BFILL_SECONDARY, 0x17
.set OFST_RBORDER_PRIMARY, 0x21
.set OFST_BBORDER_PRIMARY, 0x35
.set OFST_BBORDER_SECONDARY, 0x37

.set CONST_BLUE_R, 0x0
.set CONST_BLUE_B, 0x80 # 0x80 is equivalent to blue 255

.set CONST_RED_R, 0x80
.set CONST_RED_B_PRIMARY, 0x0
.set CONST_RED_B_SECONDARY, 0x33 # Ends up being blue 101 (lightens the red)

# Prepare base address
load r6, ADDR_COLOR_BASE # r6 should be safe to use

# Check to see if we are hovering over PS. This happens when r30 = 0x12
cmpwi r30, 0x12
beq- IsHoveringPS

# Here we are not hovering PS, make blink red
# Here we are hovering PS, make blink blue
li r3, CONST_RED_R
stb r3, OFST_RFILL_PRIMARY(r6)
stb r3, OFST_RBORDER_PRIMARY(r6)

li r3, CONST_RED_B_PRIMARY
stb r3, OFST_BFILL_PRIMARY(r6)
stb r3, OFST_BBORDER_PRIMARY(r6)

li r3, CONST_RED_B_SECONDARY
stb r3, OFST_BFILL_SECONDARY(r6)
stb r3, OFST_BBORDER_SECONDARY(r6)

b Exit

IsHoveringPS:
# Here we are hovering PS, make blink blue
li r3, CONST_BLUE_R
stb r3, OFST_RFILL_PRIMARY(r6)
stb r3, OFST_RBORDER_PRIMARY(r6)

li r3, CONST_BLUE_B
stb r3, OFST_BFILL_PRIMARY(r6)
stb r3, OFST_BFILL_SECONDARY(r6)
stb r3, OFST_BBORDER_PRIMARY(r6)
stb r3, OFST_BBORDER_SECONDARY(r6)

Exit:
li r3, 4
