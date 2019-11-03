################################################################################
# Address: 802fcce8
################################################################################

/************************************************
* Automatically Scale Name Tag Shadow Box Size *
************************************************/

/*802fcc44   NameTag_DisplayInGame

802fcce8 - lwz r3,0x10(r30)

at this point, r3+0x2c = float, x scale of backgound shadow box (and colored arrow pointing to player)

- proper scale would be (number of characters)/4, if (number of characters) is greater than 4.

Logic:
1) Pull player number, which I think I can do with
lbz r3,0(r31)

2) Branch to PlayerBlock_NameTagSlotLoad
3) Multiply that number by (space between each nametag)
4) Add to first name tag location

5) Now..count nametag length. I think I can make it work with Dan's name tag code and regular non-standard ASCII ones.

load 0x1 byte & update.
  - if zero, then end.
  - if less than 0x80, then add 1
  - else (it's normal..), so add 1 & update

6) compare size to 5
blt END

7) [float] tag length divided by [float] 4
8) store at x scale.

8045D850  First Name Tag
- name tags are 0x1a4 apart

inject @ 802fcce8 - lwz r3,0x10(r30)
*/

#load function PlayerBlock_LoadNameTagNumber
lis r3,0x8003
ori r3,r3,0x556c
mtlr r3
#load slot number
lbz r3,0(r31)
#get name tag number this slot is using
blrl


rlwinm r0,r3,0,24,31
cmplwi r0,120
#ignore if no tag
beq- END

#-0x1 from first name tag
lis r3,0x8045
ori r3,r3,0xd84f
mulli r0,r0,0x1a4
#get to this name tag
add r3,r3,r0
#initialize length counter
li r4,0

COUNT_CHARACTER_LOOP:
lbzu r0,1(r3)
cmpwi r0,0
beq- CHARACTER_LOOP_END
addi r4,r4,1
#check if normal tag type or reg ASCII
cmpwi r0,0x80
blt- COUNT_CHARACTER_LOOP
#normal name tag type
lbzu r0,1(r3)
b COUNT_CHARACTER_LOOP

CHARACTER_LOOP_END:
cmpwi r4,5
blt- END

SCALE_SHADOW_BOX:

lis r3,0x4080
stw r3,-0x10(sp)
#f17 holds 4
lfs f17,-0x10(sp)

CONVERT_INT_TO_FLOAT:

#r4 = input, f15 = output
lis r18,0x4330
lfd f16,-0x73a8(rtoc)
stw r18,-0x14(sp)
stw r4,-0x10(sp)
lfd f15,-0x14(sp)
fsubs f15,f15,f16

fdivs f15,f15,f17
#load pointer to object data
lwz r3,0x10(r30)
#store new x scale
stfs f15,0x2c(r3)

END:
#default code line
lwz r3,0x10(r30)
