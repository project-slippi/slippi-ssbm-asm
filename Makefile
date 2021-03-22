# -----------------------------------------------------------------------------

# netplay.json and playback.json also build versions of GALJ01r2.ini for NTSC-J
NETPLAY_INI 		:= Output/Netplay/GALE01r2.ini
PLAYBACK_INI 		:= Output/Playback/GALE01r2.ini
ONLINE_INI 		:= Output/Online/online.txt

# GCT output for Nintendont
C_DIR			:= Output/Console
CONSOLE_CORE 		:= $(C_DIR)/g_core.bin
CONSOLE_CORE_PORTA   	:= $(C_DIR)/g_core_porta.bin
CONSOLE_UCF		:= $(C_DIR)/g_ucf.bin
CONSOLE_UCF_STEALTH	:= $(C_DIR)/g_ucf_stealth.bin
CONSOLE_TOGGLES		:= $(C_DIR)/g_toggles.bin
CONSOLE_MODS_STEALTH	:= $(C_DIR)/g_mods_stealth.bin
CONSOLE_MODS_TOURNAMENT	:= $(C_DIR)/g_mods_tournament.bin
CONSOLE_MODS_FRIENDLIES	:= $(C_DIR)/g_mods_friendlies.bin
CONSOLE_PAL		:= $(C_DIR)/g_pal.bin
CONSOLE_FROZEN   	:= $(C_DIR)/g_frozen.bin
CONSOLE_LAG_PD		:= $(C_DIR)/g_lag_pd.bin
CONSOLE_LAG_PDVB	:= $(C_DIR)/g_lag_pdvb.bin
CONSOLE			:= $(CONSOLE_CORE) \
	$(CONSOLE_CORE_PORTA) $(CONSOLE_UCF) $(CONSOLE_UCF_STEALTH) \
	$(CONSOLE_TOGGLES) $(CONSOLE_MODS_STEALTH) $(CONSOLE_MODS_TOURNAMENT) \
	$(CONSOLE_MODS_FRIENDLIES) $(CONSOLE_PAL) $(CONSOLE_FROZEN) \
	$(CONSOLE_LAG_PD) $(CONSOLE_LAG_PDVB)

ALL_TARGETS 		:= $(ONLINE_INI) $(NETPLAY_INI) $(PLAYBACK_INI) $(CONSOLE)
.PHONY: $(ALL_TARGETS) clean
all: $(ALL_TARGETS)

# -----------------------------------------------------------------------------
# Targets for binaries to-be-included in the Slippi Nintendont tree

$(CONSOLE_CORE): console_core.json
	gecko build -defsym "STG_EXIIndex=1" -o "$(CONSOLE_CORE)" -c $<
	@echo ""

$(CONSOLE_CORE_PORTA): console_core.json
	gecko build -defsym "STG_EXIIndex=0" -o "$(CONSOLE_CORE_PORTA)" -c $<
	@echo ""

$(CONSOLE_TOGGLES): console_ControllerFixPlayerToggles.json
	gecko build -c $<
	@echo ""

$(CONSOLE_UCF): console_UCF.json
	gecko build -c $<
	@echo ""

$(CONSOLE_UCF_STEALTH): console_UCF_stealth.json
	gecko build -c $<
	@echo ""

$(CONSOLE_MODS_STEALTH): console_mods_stealth.json
	gecko build -c $<
	@echo ""

$(CONSOLE_MODS_TOURNAMENT): console_mods_tournament.json
	gecko build -c $<
	@echo ""

$(CONSOLE_MODS_FRIENDLIES): console_mods_friendlies.json
	gecko build -c $<
	@echo ""

$(CONSOLE_PAL): console_PAL.json
	gecko build -c $<
	@echo ""

$(CONSOLE_FROZEN): console_frozen.json
	gecko build -c $<
	@echo ""

$(CONSOLE_LAG_PD): console_lag_pd.json
	gecko build -c $<
	@echo ""

$(CONSOLE_LAG_PDVB): console_lag_pdvb.json
	gecko build -c $<
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
