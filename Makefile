CONSOLE_MINIMAL := Output/Console/GALE01_minimal.gct
CONSOLE 	:= Output/Console/GALE01.gct
NETPLAY 	:= Output/Netplay/GALE01r2.ini
PLAYBACK 	:= Output/Playback/GALE01r2.ini
ALL_TARGETS := $(CONSOLE_MINIMAL) $(CONSOLE) $(NETPLAY) $(PLAYBACK)

.PHONY: $(ALL_TARGETS) clean
all: $(ALL_TARGETS)

$(CONSOLE): console.json
	@gecko build -c $<
	@echo ""
$(CONSOLE_MINIMAL): console_minimal.json
	@gecko build -c $<
	@echo ""
$(NETPLAY): netplay.json
	@gecko build -c $<
	@echo ""
$(PLAYBACK): playback.json
	@gecko build -c $<
	@echo ""
clean:
	rm -f $(ALL_TARGETS)
