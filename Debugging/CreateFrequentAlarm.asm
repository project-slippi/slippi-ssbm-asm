################################################################################
# Address: 0x80019ba4
################################################################################

.include "Common/Common.s"

b CODE_START

STATIC_MEMORY_TABLE_BLRL:
blrl
.long 5000 # Period of the alarm
.fill 0x28, 1, 0 # Alarm struct is 0x28 long (I think)

ALARM_HANDLER:
blrl
# Backup
mflr r0
stw r0, 0x4(r1)
stwu r1,-0xB0(r1)	# make space for 12 registers
stmw r14,0x8(r1)

# Overwrite volatile registers
li r3, 0xFF
li r4, 0xFF
li r5, 0xFF
li r6, 0xFF
li r7, 0xFF
li r8, 0xFF
li r9, 0xFF
li r10, 0xFF
li r11, 0xFF
li r12, 0xFF

# Overwrite non-volatile registers
li r14, 0xFF
li r15, 0xFF
li r16, 0xFF
li r17, 0xFF
li r18, 0xFF
li r19, 0xFF
li r20, 0xFF
li r21, 0xFF
li r22, 0xFF
li r23, 0xFF
li r24, 0xFF
li r25, 0xFF
li r26, 0xFF
li r27, 0xFF
li r28, 0xFF
li r29, 0xFF
li r30, 0xFF
li r31, 0xFF

# Restore
lmw r14,0x8(r1)
lwz r0, 0xB4(r1)
addi r1,r1,0xB0	# release the space
mtlr r0
blr

CODE_START:

bl STATIC_MEMORY_TABLE_BLRL
mflr r3
addi r3, r3, 0x4
branchl r12, 0x8034376c # OSCreateAlarm

bl STATIC_MEMORY_TABLE_BLRL
mflr r3
addi r3, r3, 0x4
li r4, 0
li r5, 0
lwz r6, -0x4(r3)
li r7, 0
lwz r8, -0x4(r3)
bl ALARM_HANDLER
mflr r9
branchl r12, 0x80343a30 # OSSetPeriodicAlarm

# replaced code line
lmw	r27, 0x0034 (sp)