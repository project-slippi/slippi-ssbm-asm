################################################################################
# Address: 0x8025ac6c
# Animates the "stage select" and "alt stage" textures based on cursor hover
################################################################################

.include "Common/Common.s"
.include "./SSSToggles.s"

.set REG_GOBJ, 31
.set REG_JOBJ, 30
.set REG_UDATA, 29
.set JObj_ForEachAnim, 0x80364C08
.set JObj_RemoveAnimAll, 0x8036f6b4
.set JObj_GetAnimFrame, 0x8022f298
.set AOBJ_ReqAnim, 0x8036410C
.set AOBJ_StopAnim, 0x8036414C

CODE_START:
  backup
  mr REG_GOBJ, r3

# alloc data
  li r3, 12
  branchl r12, HSD_MemAlloc
  mr REG_UDATA, r3
# zero data
  li r4, 12
  branchl r12, Zero_AreaLength

# add to gobj
  mr r3, REG_GOBJ
  li r4, 4
  load r5, HSD_Free
  mr r6, REG_UDATA
  branchl r12, GObj_AddUserData

# add proc
  mr r3, REG_GOBJ
  bl FN_AnimBackgroundText_BLRL
  mflr r4
  li r5, 0
  branchl r12, GObj_AddProc

  b EXIT

################################################################################
FN_AnimBackgroundText_BLRL:
blrl
# regs
.set REG_UDATA, 29
.set REG_TXT_FRAME, 28
.set REG_ALT_FRAME, 27
.set REG_STATE, 26
.set REG_TXT_JOBJ, 25
.set REG_ALT_JOBJ, 24
.set REG_MAX, 23
# data
.set TEXT_FRAME, 0
.set ALT_FRAME, TEXT_FRAME + 4
.set ANIM_STATE, ALT_FRAME + 4
# constants
.set DEFAULT_MAX, 20

FN_AnimBackgroundText:
  backup

# init vars
  mr REG_GOBJ, r3
  lwz REG_JOBJ, 0x28(REG_GOBJ)
  lwz REG_TXT_JOBJ, 0x10(REG_JOBJ)
  lwz REG_TXT_JOBJ, 0x8(REG_TXT_JOBJ)
  lwz REG_ALT_JOBJ, 0x8(REG_TXT_JOBJ)

  lwz REG_UDATA, 0x2C(REG_GOBJ)
  lwz REG_TXT_FRAME, TEXT_FRAME(REG_UDATA)
  lwz REG_ALT_FRAME, ALT_FRAME(REG_UDATA)

# decide hover state
CHECK_STATE:
  loadbz r3, SSS_HoveredIcon
  cmpwi r3, ID_GRPS
  beq SET_ALT_STATE

SET_DEFAULT_STATE:
  li r4, 0
  stw r4, ANIM_STATE(REG_UDATA)
  b ANIMATE_START

SET_ALT_STATE:
  li r4, 1
  stw r4, ANIM_STATE(REG_UDATA)

ANIMATE_START:
  lwz REG_TXT_FRAME, TEXT_FRAME(REG_UDATA)
  lwz REG_ALT_FRAME, ALT_FRAME(REG_UDATA)
  lwz REG_STATE, ANIM_STATE(REG_UDATA)

# forward when unhovered , reverse when hovered
  cmpwi REG_STATE, 0
  beq TEXT_FORWARD
  b TEXT_REVERSE

TEXT_FORWARD:
  cmpwi REG_TXT_FRAME, DEFAULT_MAX
  bge TEXT_DONE # if >= max, skip
  addi REG_TXT_FRAME, REG_TXT_FRAME, 1
  stw REG_TXT_FRAME, TEXT_FRAME(REG_UDATA)
  mr r3, REG_TXT_FRAME
  branchl r12, FN_IntToFloat
  mr r3, REG_TXT_JOBJ
  branchl r12, JObj_ReqAnimAll
  mr r3, REG_TXT_JOBJ
  branchl r12, JObj_AnimAll
  b TEXT_DONE

TEXT_REVERSE:
  cmpwi REG_TXT_FRAME, 0
  ble TEXT_DONE # if <= 0, skip
  subi REG_TXT_FRAME, REG_TXT_FRAME, 1
  stw REG_TXT_FRAME, TEXT_FRAME(REG_UDATA)
  mr r3, REG_TXT_FRAME
  branchl r12, FN_IntToFloat
  mr r3, REG_TXT_JOBJ
  branchl r12, JObj_ReqAnimAll
  mr r3, REG_TXT_JOBJ
  branchl r12, JObj_AnimAll

TEXT_DONE:
  cmpwi REG_STATE, 1
  beq ALT_FORWARD
  b ALT_REVERSE

ALT_FORWARD:
  cmpwi REG_ALT_FRAME, DEFAULT_MAX
  bge ALT_DONE
  addi REG_ALT_FRAME, REG_ALT_FRAME, 1
  stw REG_ALT_FRAME, ALT_FRAME(REG_UDATA)
  mr r3, REG_ALT_FRAME
  branchl r12, FN_IntToFloat
  mr r3, REG_ALT_JOBJ
  branchl r12, JObj_ReqAnimAll
  mr r3, REG_ALT_JOBJ
  branchl r12, JObj_AnimAll
  b ALT_DONE

ALT_REVERSE:
  cmpwi REG_ALT_FRAME, 0
  ble ALT_DONE
  subi REG_ALT_FRAME, REG_ALT_FRAME, 1
  stw REG_ALT_FRAME, ALT_FRAME(REG_UDATA)
  mr r3, REG_ALT_FRAME
  branchl r12, FN_IntToFloat
  mr r3, REG_ALT_JOBJ
  branchl r12, JObj_ReqAnimAll
  mr r3, REG_ALT_JOBJ
  branchl r12, JObj_AnimAll

ALT_DONE:
  mr r3, REG_JOBJ
  branchl r12, JObj_Anim
  lwz r3, 0x10(REG_JOBJ)
  branchl r12, JObj_Anim

  # lwz r5, TEXT_FRAME(REG_UDATA)
  # lwz r6, ALT_FRAME(REG_UDATA)
  # logf LOG_LEVEL_WARN, "[T FRAME, ALT FRAME] %d, %d\n"

  restore
  blr
################################################################################

EXIT:
  restore
  