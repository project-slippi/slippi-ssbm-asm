################################################################################
# Address: 8025a530
################################################################################
.include "Common/Common.s"

.set OFST_COLOR_BASE, 0x6f208 - 0x20
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

# Only run this injection if selected stage has changed
lbz r3, -0x49F2(r13)
cmpw r3, r30
beq Exit

# Prepare base address
lwz	r3, -0x4A0C (r13)     #access pointer to dat file in memory
lwz r3,0x20(r3)           #access pointer to 0x20 of dat file in memory
load r4,OFST_COLOR_BASE   #get to color data in dat file
add r6,r3,r4

# Check to see if we are hovering over PS. This happens when r30 = 0x12
cmpwi r30, 0x12 # PS
beq- IsHoveringFrozen

cmpwi r30, 0x1a # Dreamland
beq- IsHoveringFrozen

cmpwi r30, 0x6 # Yoshis
beq- IsHoveringFrozen

cmpwi r30, 0x19 # FD
beq- IsHoveringFrozen

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

b ResetAnimation

IsHoveringFrozen:
# Here we are hovering PS, make blink blue
li r3, CONST_BLUE_R
stb r3, OFST_RFILL_PRIMARY(r6)
stb r3, OFST_RBORDER_PRIMARY(r6)

li r3, CONST_BLUE_B
stb r3, OFST_BFILL_PRIMARY(r6)
stb r3, OFST_BFILL_SECONDARY(r6)
stb r3, OFST_BBORDER_PRIMARY(r6)
stb r3, OFST_BBORDER_SECONDARY(r6)

ResetAnimation:
#Reset animation. This is to force the color to change immediately
lwz r3, -0x472C (r13)
lwz r3,0x2C(r3)
li  r4,9
stw r4,0x0(r3)

Exit:
stb r30, -0x49F2(r13)
