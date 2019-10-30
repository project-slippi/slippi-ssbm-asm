# -----------------------------------------------------------------------------

# netplay.json and playback.json also build versions of GALJ01r2.ini for NTSC-J
NETPLAY_INI 		:= Output/Netplay/GALE01r2.ini
PLAYBACK_INI 		:= Output/Playback/GALE01r2.ini

# GCT output for Nintendont
C_DIR			:= Output/Console
CONSOLE_CORE 		:= $(C_DIR)/g_core.bin
CONSOLE_CORE_PORTA   := $(C_DIR)/g_core_porta.bin
CONSOLE_UCF		:= $(C_DIR)/g_ucf.bin
CONSOLE_TOGGLES		:= $(C_DIR)/g_toggles.bin
CONSOLE_SPAWNS		:= $(C_DIR)/g_tournament.bin
CONSOLE_PAL		:= $(C_DIR)/g_pal.bin
CONSOLE_QOL		:= $(C_DIR)/g_qol.bin
CONSOLE			:= $(CONSOLE_CORE) $(CONSOLE_CORE_PORTA) $(CONSOLE_UCF) \
				$(CONSOLE_TOGGLES) $(CONSOLE_SPAWNS) $(CONSOLE_PAL) $(CONSOLE_QOL)

ALL_TARGETS 		:= $(NETPLAY_INI) $(PLAYBACK_INI) $(CONSOLE)
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
