################################################################################
# Address: 800ac5b8
# Tags: [affects-gameplay]
################################################################################

mr r29, r3 # replaced code line

# There seems to be a bug in the game where undefined values are used for X/Y stick values
# under certain conditions when Nana is DI'ing a throw. This happens at lines 800ac74c and
# 800ac75c where r5 can be unset, r30 can also be unset which is loaded into r5 for the second call.
#
# If the gecko code list for one player is different than another (for example if they enable
# an option code), the undefined values can be different, causing a desync.
#
# By initializing r5 and r30 to 0, we ensure that the same values are used for both players.

li r5, 0
li r30, 0