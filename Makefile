# -----------------------------------------------------------------------------

# netplay.json and playback.json also build versions of GALJ01r2.ini for NTSC-J
NETPLAY_INI 		:= Output/Netplay/GALE01r2.ini
PLAYBACK_INI 		:= Output/Playback/GALE01r2.ini
ONLINE_INI  		:= Output/Online/online.txt

# GCT output for Nintendont
# to add a new json just create a new var with the json name
# and then add it to the CONSOLE list
CONSOLE_CORE            := core
CONSOLE_CORE_PORTA      := core_porta
CONSOLE_UCF             := console_UCF.json
CONSOLE_UCF_STEALTH     := console_UCF_stealth.json
CONSOLE_MODS_STEALTH    := console_mods_stealth.json
CONSOLE_MODS_TOURNAMENT := console_mods_tournament.json
CONSOLE_MODS_FRIENDLIES := console_mods_friendlies.json
CONSOLE_PAL             := console_PAL.json
CONSOLE_FROZEN_PS       := console_stages_stadium.json
CONSOLE_FROZEN_ALL      := console_stages_all.json
CONSOLE_GAMEPLAY_LGL    := console_gameplay_lgl.json
CONSOLE_GAMEPLAY_WOBBLE := console_gameplay_wobbling.json
CONSOLE_GAMEPLAY_BOTH   := console_gameplay_both.json
CONSOLE_LAG_PD          := console_lag_pd.json
CONSOLE_LAG_PDHALFVB    := console_lag_pdhalfvb.json
CONSOLE_SCREEN_WIDE     := console_screen_wide.json
CONSOLE_SCREEN_SHUTTERS := console_screen_wide_shutters.json
CONSOLE_SAFETY          := console_safety.json
CONSOLE                 := $(CONSOLE_UCF) $(CONSOLE_UCF_STEALTH) \
	$(CONSOLE_MODS_STEALTH) $(CONSOLE_MODS_TOURNAMENT) $(CONSOLE_MODS_FRIENDLIES) \
	$(CONSOLE_PAL) $(CONSOLE_FROZEN_PS) $(CONSOLE_FROZEN_ALL) $(CONSOLE_GAMEPLAY_LGL) \
	$(CONSOLE_GAMEPLAY_WOBBLE) $(CONSOLE_GAMEPLAY_BOTH) $(CONSOLE_LAG_PD) $(CONSOLE_LAG_PDHALFVB) \
	$(CONSOLE_SCREEN_WIDE) $(CONSOLE_SCREEN_SHUTTERS) $(CONSOLE_SAFETY)

ALL_TARGETS := $(ONLINE_INI) $(NETPLAY_INI) $(PLAYBACK_INI) \
			$(CONSOLE_CORE_PORTA) $(CONSOLE_CORE) $(CONSOLE)
.PHONY: $(ALL_TARGETS) clean
all: $(ALL_TARGETS)

# -----------------------------------------------------------------------------
# Targets for binaries to-be-included in the Slippi Nintendont tree

$(CONSOLE_CORE): console_core.json
	gecko build -defsym "STG_EXIIndex=1" -o "Output/Console/g_core.bin" -c $<
	@echo ""

$(CONSOLE_CORE_PORTA): console_core.json
	gecko build -defsym "STG_EXIIndex=0" -o "Output/Console/g_core_porta.bin" -c $<
	@echo ""

$(CONSOLE):
	gecko build -c $@
	@echo ""

# -----------------------------------------------------------------------------
# Targets for Dolphin's {netplay,playback} .ini configuration files

$(NETPLAY_INI): netplay.json
	@gecko build -defsym "STG_EXIIndex=1" -c $<
	@echo ""
$(PLAYBACK_INI): playback.json
	@gecko build -defsym "STG_EXIIndex=1" -c $<
	@echo ""

# -----------------------------------------------------------------------------
clean:
	rm -f $(ALL_TARGETS)
