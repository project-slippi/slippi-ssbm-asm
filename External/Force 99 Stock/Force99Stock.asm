################################################################################
# Address: 0x8016e760
################################################################################

# Note that this code is not 100% compatible with replays. The game start block will not have
# the 99 stocks. That said, the replay still plays correctly with resync logic as the stocks get
# synced. The only other known problem with this is that the punishes don't show the stocks
# correctly on the stats page. But there might be other issues when logic relies on the game start
# block having the correct starting stocks value

li r3, 99
stb r3, (0x62+(0 * 0x24))(r31) # p1
stb r3, (0x62+(1 * 0x24))(r31) # p2
stb r3, (0x62+(2 * 0x24))(r31) # p3
stb r3, (0x62+(3 * 0x24))(r31) # p4

lis	r3, 0x8022 # replaced code line