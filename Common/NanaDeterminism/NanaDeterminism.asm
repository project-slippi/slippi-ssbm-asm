################################################################################
# Address: 800ac5b8
# Tags: [affects-gameplay]
################################################################################

mr r29, r3 # replaced code line

# There is a scenario where r30 is undefined and is passed to a function at line 800ac754. This
# value then gets used for a stb in the called function and impacts Nana's inputs. The value when
# undefined often holds a memory address which doesn't make sense for stb. There is a fair chance
# this is a bug with Melee which causes it to be undeterministic. By initializing the value, we
# hopefully solve this problem
li r30, 0