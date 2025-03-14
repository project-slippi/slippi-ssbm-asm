################################################################################
# Address: 0x8000c160 # Zero_AreaLength (see notes below)
################################################################################
.include "Common/Common.s"
.include "Online/Online.s"
.include "Recording/Recording.s"

  # This is a jank injection location because we need to run this after InitOnlinePlay but
  # before SendGameInfo. We are injecting here to hijack a function call from SendGameInfo.
  # Overwriting the settings in this particular location is important because it happens
  # after the online mode game block has been set up but before the game block is written
  # to the replay file. This allows for the replays to play back with the correct settings.
  # This injection is designed to only overwrite settings in direct and teams modes.

  # Check if in an online in-game scene. If not, don't run the code
  getMinorMajor r7
  cmpwi r7, SCENE_ONLINE_IN_GAME
  bne Exit

  # If in ranked or unranked, don't run the code
  lbz r7, OFST_R13_ONLINE_MODE(r13)
  cmpwi r7, ONLINE_MODE_RANKED
  beq Exit
  cmpwi r7, ONLINE_MODE_UNRANKED
  beq Exit

  # This should check if we are in StartMelee by looking for the return loc in the stack.
  # This means we will actually run the settings override multiple times including when
  # we don't really need to but I don't think it's going to break anything. As long
  # as it happens the one time we need it, that's all that matters.
  lwz r7, 0x104(r1)
  load r8, 0x8016e94c
  cmpw r7, r8
  bne Exit

  # For every other online mode (direct, teams), run the code

EditRules:

  .set GameInfoBlock, 0x80480530
  .set ItemFrequency, 0xB
  .set ItemsMedium, 0x02

  load r8, GameInfoBlock
  
  li r7, ItemsMedium
  stb r7, ItemFrequency (r8)

Exit:
  cmpwi r4, 0 # replaced code line