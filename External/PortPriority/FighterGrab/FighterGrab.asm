################################################################################
# Address: 0x80078C04
# Tags: [affects-gameplay]
################################################################################
.set HSD_Randi, 0x80380580
.set CheckPrevHitPlayers, 0x8000ACFC 
.set CompareScaleZ, 0x8007F804
.set GrabCheckOverlap, 0x80007ECC
.set LineCheckObstruct, 0x80084CE4
.set CheckNextGObj, 0x80078C4C

stfs f1,0x20(sp) #Backup this fighter's unk grab position var in stack

addi r3,r29,0 #Current victim's GObj
addi r4,r25,0 #This GObj
bl lbl_GrabCheckVictim

cmpwi r3,0 #Check if victim is also grabbing this fighter
beq- lbl_Win #If victim is not feeling touchy, this fighter wins the interaction

lfs f1,0x1830(r30) #This fighter's damage
lfs f0,0x1830(r28) #Victim's damage

fcmpo cr0,f1,f0 #Compare this fighter's % to victim's
cror 2,0,2 #OR cr0_lt with cr0_eq and put result in cr_eq to dodge NaN edge cases
bne- lbl_Lose #If this fighter has a higher % than the victim, lose the interaction

fcmpu cr0,f1,f0 #Check if both %s are equal
bne- lbl_Win #If this fighter REALLY has less damage than the victim, win the grab

li r3,2 #Load 2 into randomizer to get a 50/50 chance to beat victim if %s are equal
branchl r12,HSD_Randi #HSD integer randomizer

cmpwi r3,0
beq- lbl_Lose #If result is 0, lose the interaction

lbl_Win:
lwz r0,0(r28) #Get victim's GObj pointer
b lbl_EXIT #Go to injection exit

lbl_Lose:

#Documentation on 0x1A58 and 0x1A5C is conflicting, not entirely sure what their 
#true purpose is, but they are both related to attacker/victim logic
#li r0,0 #Set r0 to NULL
#stw r0,0x1A5C(r30) #Store NULL pointer to this fighter's hitlag partner pointer?
#stw r0,0x1A58(r30) #Store NULL pointer to this fighter's victim pointer?
#lbz r3,0x221B(r30) #Load flags at 0x221B
#rlwimi r3,r0,2,29,29 #Move r0 over bit 29 of r3
#stb r3,0x221B(r30) #Grab bool is now false
#lfs f1,0x20(sp) #Load grab position thingy

branch r12,CheckNextGObj #Go to line of code that stores grab position thingy

lbl_EXIT:
lfs f1,0x20(sp) #Load grab position thingy
b lbl_Return

.set rHitLoop, 31
.set rThisFP, 30
.set rVicFP, 29
.set rLoopHitbox, 28
.set rHit, 27
.set rThisObj, 26
.set rVicHurtbox, 25
.set rLoopHurtbox, 24
.set rReturn, 23

lbl_GrabCheckVictim:

mflr r0 #Get return pointer from link register
stw r0,0x4(sp) #Store link register at top of current stack position
stwu sp,-0x40(sp) #Make space for 0x40 bytes in the stack
stfd f31,0x38(sp) #Backup f31 so we can store 0.0F to it
stmw r23,0x14(sp) #Backup all registers from r23 until r31

addi rThisObj,r3,0 #Store this GObj
lwz rThisFP,0x2C(rThisObj) #Get this GObjs user_data
lwz rVicFP,0x2C(r4) #Get victim's user_data

li rLoopHitbox,0 #Init loop counter

lfs f0,-0x76D0(rtoc)
stfs f0,0x216C(rThisFP) #Get and store maximum single-precision float limit

addi rHitLoop,rThisFP,0 #Move this fighter's data to temporary hitbox loop register

li rReturn,0 #Init return value, this stays at "false" unless all checks are passed

lfs f31,-0x7700(rtoc) #Load 0.0F

lbl_LoopHitboxStart:
addi r3,rHitLoop,0x914 #Get address of the start of this fighter's hitbox array
lwz r0,0x914(rThisFP) #Load hitbox state
addi rHit,r3,0 #Move hitbox struct address to reserved hitbox register 
cmpwi r0,0 #Check if hitbox state is "disabled"
beq- lbl_LoopIncHitbox #If hitbox is disabled, check for the next one

lwz r0,0x30(r3) #Get hitbox element
cmplwi r0,8 #Check if hitbox's element is "grab"
bne- lbl_LoopIncHitbox #If we're not dealing with a grabbox, check next hitbox

lbz r0,0x40(r3) #Get hitbox flags
rlwinm. r0,r0,27,31,31 #Check to ignore airborne fighters
beq- lbl_CheckFlagNext
lwz r0,0xE0(rVicFP) #Get ground_or_air
cmpwi r0,1 #Check if fighter is airborne
beq- lbl_SkipToCheckPrevHit
lbl_CheckFlagNext:
lbz r0,0x40(r3) #Get hitbox flags
rlwinm. r0,r0,28,31,31 #Check if fighter is grounded
beq- lbl_LoopIncHitbox
lwz r0,0xE0(rVicFP) #Get grorund_or_air
cmpwi r0,0 #Check if fighter is grounded
bne- lbl_LoopIncHitbox #Check next hitbox if airborne

lbl_SkipToCheckPrevHit:
addi r3,rVicFP,0
addi r4,rHit,0
branchl r12,CheckPrevHitPlayers #Check previously hit players

cmpwi r3,0
bne- lbl_LoopIncHitbox #Check next hitbox if victim has already been hit by this one

addi rVicHurtbox,rVicFP,0 #Move victim's user_data to temporary hurtbox register
li rLoopHurtbox,0 #Init hurtbox loop
b lbl_LoopHurtboxCheck #Go to hurtbox loop count

lbl_LoopHurtboxStart:
lwz r0,0x11E8(rVicHurtbox) #Get hurtbox's grab enable bool?
cmpwi r0,0
beq- lbl_LoopIncHitboxHurtbox #If hurtbox cannot be grabbed, check the next one

mr r3,rVicFP 
branchl r12,CompreScaleZ #Compare victim's Z-scale to 0.0F

lfs f1,0x38(rThisFP) #Get this fighter's Y-scale
mr r5,r3 #Move float* address of Z-scale?
lfs f2,0x38(rVicFP) #Get victim's Y-scale
mr r3,rHit
lfs f3,0xB8(rVicFP) #Get victim's current Z-position
addi r4,rVicHurtbox,4512 #Address of current hurtbox's data
branchl r12,GrabCheckOverlap #Check for grab overlap

cmpwi r3,0
beq- lbl_LoopIncHitboxHurtbox #If there is no overlap, check the next hurtbox

addi r3,rThisFP,0 
addi r4,rVicFP,0
branchl r12,LineCheckObstruct #Check for obstructions between the two fighters

cmpwi r3,0
bne- lbl_END #If there are obstructions, exit the function with FALSE in r23

#Series of initializations from original grab logic, to flag the victim as if we've attacked them
#We don't want that in this case, so this block is commented out
#addi r3,rThisFP,0
#addi r4,rHit,0
#addi r6,rVicFP,0
#li r5,0
#li r7,0
#bl 0x80076808

lfs f1,0xB0(rVicFP) #Get victim's X-position
lfs f0,0xB0(rThisFP) #Get this fighter's X-position

fsubs f1,f1,f0 #Subtract this fighter's X-pos from victim's X-pos
fcmpo cr0,f1,f31 #Compare to 0.0F
bge- lbl_SkipNeg #If positive, value is already absolute

fneg f1,f1 #Otherwise, flip the sign bit of the negative result (fabs)

lbl_SkipNeg:
lfs f0,0x216C(rThisFP) #Get this fighter's grab distance threshold
fcmpo cr0,f1,f0 #Compare position to 0x216C
bge- lbl_END #Return with FALSE in r23

li rReturn,1 #Now, all checks have been passed; both players' grabs overlap
b lbl_END #Return with TRUE in r23

lbl_LoopIncHitboxHurtbox:
addi rVicHurtbox, rVicHurtbox, 76 #Get address of next hurtbox struct
addi rLoopHurtbox, rLoopHurtbox, 1 #Incremennt hurtbox loop counter

lbl_LoopHurtboxCheck:
lbz r0,0x119E(rVicFP) #Get victim's hurtbox count
cmplw rLoopHurtbox,r0 #Check if hurtbox loop count has exceeded victim's number of hurtboxes
blt+ lbl_LoopHurtboxStart 

lbl_LoopIncHitbox:
addi rLoopHitbox,rLoopHitbox,1 #Increment hitbox loop count
cmplwi rLoopHitbox,4 #Check if all four hitboxes have been compared
addi rHitLoop, rHitLoop, 0x138 #Add size of hurtbox struct to temporary hitbox register
blt+ lbl_LoopHitboxStart

lbl_END:
mr r3,rReturn #Return isOverlap bool
lmw r23,0x14(sp) #Restore all non-volatile registers and return
lwz r0,0x44(sp) #Load return pointer into r0
lfd f31,0x38(sp) #Restore f31
addi sp,sp,0x40 #Restore stack position
mtlr r0 #Move return pointer from r0 into link register
blr #Return from subroutine

lbl_Return: