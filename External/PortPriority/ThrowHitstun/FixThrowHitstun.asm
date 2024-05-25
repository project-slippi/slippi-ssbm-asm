################################################################################
# Address: 0x8008E25C
# Tags: [affects-gameplay]
################################################################################

lwz r4,0x1198(r29) #Get thrower GObj pointer
cmplwi r4,0           
beq- lbl_FrameAdvance #Run original code if NULL
lwz r4,0x2C(r4)
lbz r4,0xC(r4)  #Get port ID of thrower
lbz r0,0xC(r29) #Get port ID of victim
cmpw r0,r4
bgt- lbl_Skip #If victim is lower priority, skip frame advance
lbl_FrameAdvance:
lis r12, 0x8007
subi r12, r12, 0x145C
mtlr r12
blrl 
b lbl_END #Exit
lbl_Skip:
lfs f1,0x2340(r29) #Load victim's hitstun frames
lfs f0,-0x7508(rtoc) #Load 1.0F
fadds f0,f1,f0 #hitstun += 1.0F;
stfs f0,0x2340(r29) #Store fixed hitstun
lbl_END: