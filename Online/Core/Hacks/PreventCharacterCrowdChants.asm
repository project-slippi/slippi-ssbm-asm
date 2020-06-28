################################################################################
# Address: 0x80321d70 # Overwrites a function call
################################################################################

# For now this is a hack, but there's probably some condition in the function
# that prevents the sound from playing twice and that data is being cleared
# on a rollback. Should find what it is and preserve it?
li r3, 0
