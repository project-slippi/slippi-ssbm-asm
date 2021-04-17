# The CheckAutoFill injection contains static data related to auto-fill
.set INJ_CheckAutofill, 0x8023cca4

# Injection Data Offsets
.set IDO_FN_FetchSuggestion, 0x8
.set IDO_ACB_ADDR, IDO_FN_FetchSuggestion + 0x4

# Auto complete receive buffer
.set ACRXB_HAS_SUGGESTION, 0x0 # u8
.set ACRXB_SUGGESTION, ACRXB_HAS_SUGGESTION + 1 # 3 * 8, for all characters
.set ACRXB_SUGGESTION_LEN, ACRXB_SUGGESTION + (3 * 8) # u8, number of letters returned
.set ACRXB_NEW_INDEX, ACRXB_SUGGESTION_LEN + 1 # u32
.set ACRXB_SIZE, ACRXB_NEW_INDEX + 4

# Auto complete transfer buffer
.set ACTXB_CMD, 0x0 # u8
.set ACTXB_INPUT, ACTXB_CMD + 1 # 3 * 8, for all possible characters in input
.set ACTXB_INPUT_LEN, ACTXB_INPUT + (3 * 8) # u8, number of letters that have been input
.set ACTXB_INDEX, ACTXB_INPUT_LEN + 1 # u32, scroll index
.set ACTXB_SCROLL_DIR, ACTXB_INDEX + 4 # u8, See scroll option constants
.set ACTXB_MODE, ACTXB_SCROLL_DIR + 1 # u8, Mode we are currently in
.set ACTXB_SIZE, ACTXB_MODE + 1

# Set ACXB_SIZE to the larger of the two sizes
.if ACTXB_SIZE > ACRXB_SIZE
  .set ACXB_SIZE, ACTXB_SIZE
.else
  .set ACXB_SIZE, ACRXB_SIZE
.endif

# Auto Complete Buffer
.set ACB_INDEX, 0x0 # u32, index for where we are in scroll list
.set ACB_COMMITTED_CHAR_COUNT, ACB_INDEX + 4 # u8
.set ACB_ONE_SHOT_COMPLETE, ACB_COMMITTED_CHAR_COUNT + 1 # u8
.set ACB_ACXB_ADDR, ACB_ONE_SHOT_COMPLETE + 1  # u32
.set ACB_SIZE, ACB_ACXB_ADDR + 4

# Scroll option constants
.set CONST_NoScroll, 0
.set CONST_ScrollOlder, 1
.set CONST_ScrollNewer, 2
.set CONST_ScrollReset, 3
