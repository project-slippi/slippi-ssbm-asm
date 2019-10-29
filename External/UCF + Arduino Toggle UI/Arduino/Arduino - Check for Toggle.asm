################################################################################
# Address: 8006B028
################################################################################
.include "Common/Common.s"

#Original Codeline
  stw	r0, 0x065C (r31)

#Check If Enabled
  lbz	r11, 0x618 (r31)        #get player number
  subi r12,rtoc,ControllerFixOptions      #get UCF toggle bool base address
  lbzx r11,r12,r11	          #get players UCF toggle bool
  cmpwi r11,2
  bne Exit

#Start Dween Code

bl DBSTART
.long 0x00000000
.long 0x00000000
.long 0x00000000
.long 0x00000000
.long 0x3F39999A
.long 0xBF300000
.long 0x3C4CCCCD
.long 0x3E4CCCCD

DBSTART:
mflr r12
lfs f0, 0x0650(r31)
lfs f1, -0x778C(rtoc)
fcmpo cr0, f0, f1
bgt- ShieldDrop

li r4, 0x70
and. r4, r4, r0
cmpwi r4, 0
bne- ShieldDrop

li r4, 0x0E00
and. r4, r4, r0
cmpwi r4, 0
bne- END

li r4, 0x0100
and. r4, r4, r0
beq+ DashBack
lwz r5, 0x660(r31)
and. r5, r5, r4
beq- END



DashBack:
lfs f0, 0x624(r31)
fcmpo cr0, f0, f1
bne+ END
lfs f0, 0x620(r31)
fcmpo cr0, f0, f1
beq- END
fabs f0, f0
lwz r4, -0x514C(r13)
lfs f2, 0x3C(r4)
lfs f3, 0(r4)
lfs f4,8(r4)
fcmpo cr0, f0, f2
bge+ END

lbz r4, 0x618(r31)
mulli r4, r4, 4
lfsx f0, r12, r4
fabs f2, f0
fcmpo cr0, f2, f3
bge- END
lfs f2, 0x620(r31)
fsubs f2, f2, f0
fabs f2, f2
fcmpo cr0, f2, f4
blt- END
stfs f1, 0x620(r31)
b END

ShieldDrop:
lfs f0, 0x0654(r31)
lfs f2, 0x650(r31)
fmuls f0, f0, f2
fcmpo cr0, f0, f1
bgt- SDAPPLY

li r4, 0x70
and r4, r4, r0
lwz r0, 0x660(r31)
and. r4, r4, r0
bne- SDAPPLY
b END

SDAPPLY:
lfs f0, 0x620(r31)
lfs f2, 0x628(r31)
fmuls f3, f2, f0
fcmpo cr0, f3, f1
ble- END

lbz r4, 0x670(r31)
cmpwi r4, 3
blt- END

lfs f2, 0x624(r31)
lwz r4, -0x514C(r13)
lfs f3, 0x314(r4)
fcmpo cr0, f2, f3
bgt+ END
fneg f2, f2
lfs f3, 0x3C(r4)
fcmpo cr0, f2, f3
bge+ END
lfs f3, 0x18(r12)
fabs f4, f0
fadds f4, f3, f4
fadds f2, f2, f3
fmuls f4, f4, f4
fmadds f2, f2, f2, f4
lfs f3, -0x76AC (rtoc)
fcmpo cr0, f2, f3
ble- END

lfs f2, 0x10(r12)
fcmpo cr0, f0, f1
bge- 0xC
lfs f0, -0x76A8(rtoc)
fmuls f2, f0, f2
stfs f2, 0x620(r31)
lfs f2, 0x14(r12)
stfs f2, 0x624(r31)


END:
lbz r4, 0x618(r31)
mulli r4, r4, 4
lfs f0, 0x20(r3)
stfsx f0, r12, r4

Exit:
