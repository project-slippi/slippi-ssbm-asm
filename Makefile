NETPLAY_INI 		:= Output/Netplay/GALE01r2.ini
NETPLAY_INI_JP		:= Output/Netplay/GALJ01r2.ini
PLAYBACK_INI 		:= Output/Playback/GALE01r2.ini
PLAYBACK_INI_JP 	:= Output/Playback/GALJ01r2.ini

C_DIR			:= Output/Console
CONSOLE_CORE 		:= $(C_DIR)/g_core.bin
CONSOLE_UCF		:= $(C_DIR)/g_ucf.bin
CONSOLE_TOGGLES		:= $(C_DIR)/g_toggles.bin
CONSOLE_SPAWNS		:= $(C_DIR)/g_tournament.bin
CONSOLE_PAL		:= $(C_DIR)/g_pal.bin
CONSOLE_QOL		:= $(C_DIR)/g_qol.bin

CONSOLE			:= $(CONSOLE_CORE) $(CONSOLE_UCF) $(CONSOLE_TOGGLES) \
				$(CONSOLE_SPAWNS) $(CONSOLE_PAL) $(CONSOLE_QOL)

ALL_TARGETS 		:= $(NETPLAY_INI) $(PLAYBACK_INI) $(CONSOLE)
.PHONY: $(ALL_TARGETS) clean
all: $(ALL_TARGETS)

# -----------------------------------------------------------------------------
# Targets for binaries to-be-included in the Slippi Nintendont tree

$(CONSOLE_CORE): console_core.json
	gecko build -c $<
	@echo ""

$(CONSOLE_UCF): console_UCF.json
	gecko build -c $<
	@echo ""

$(CONSOLE_TOGGLES): console_ControllerFixPlayerToggles.json
	gecko build -c $<
	@echo ""

$(CONSOLE_SPAWNS): console_tournament.json
	gecko build -c $<
	@echo ""

$(CONSOLE_PAL): console_PAL.json
	gecko build -c $<
	@echo ""

$(CONSOLE_QOL): console_QOL.json
	gecko build -c $<
	@echo ""

# -----------------------------------------------------------------------------
# Targets for Dolphin's netplay/playback .ini files

$(NETPLAY_INI): netplay.json
	@gecko build -c $<
	@cp $(NETPLAY_INI) $(NETPLAY_INI_JP)
	@echo ""
$(PLAYBACK_INI): playback.json
	@gecko build -c $<
	@cp $(PLAYBACK_INI) $(PLAYBACK_INI_JP)
	@echo ""

# -----------------------------------------------------------------------------
clean:
	rm -f $(ALL_TARGETS)
