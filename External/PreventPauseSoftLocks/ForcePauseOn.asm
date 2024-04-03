################################################################################
# Address: 0x80167f40
################################################################################
# Forces pause ON unless in a stock battle with 4 stocks or less in which case
# the pause setting will be respected. Created to prevent soft locks or pseudo
# soft locks when disabling pause and playing infinite time or long match.
################################################################################

.set REG_RULES, 30 # From parent, where the rules from the CSS selections are stored

################################################################################
# ASM Research
################################################################################
# Code where rules type is checked -> 80167c08
# Code where pause setting is checked -> 80167f40

# Address where rules are read from -> 8045bf10
# Offsets for the address:
# 0x2 (u8) -> Game type (0 = Time, 1 = Stock, etc)
# 0x4 (u8) -> Stock count
# 0xa (u8) -> Pause (0 = Off, 1 = On)

lbz r0, 0x2(REG_RULES)
cmpwi r0, 1 # Check for stock mode
bne FORCE_PAUSE_ON # If not stock mode, force pause on

# Here we are in stock mode, check the number of stocks
lbz r0, 0x4(REG_RULES)
cmpwi r0, 4
bgt FORCE_PAUSE_ON # If more than 4 stocks, always enable pause

# If we get here, just use the pause setting from the CSS
lbz r0, 0xA(REG_RULES) # 1 means pause on, 0 means pause off
b EXIT

FORCE_PAUSE_ON:
li r0, 1

EXIT: