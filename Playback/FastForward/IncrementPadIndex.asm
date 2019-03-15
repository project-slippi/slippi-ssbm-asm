# Inject at 80377544

# Credit to tauKhan

# This makes it so that if we are iterating without anything in the input
# buffer, it will move the pad input along so that we correctly restore
# the x analog value used by UCF to the correct place. Previously there
# was a possibility for desyncs when doing a UCF dashback while fast forwarding

# I believe the only time this would not skip is when we force a ffw

bne- SKIP   # Continue if input buffer larger than zero (unused inputs present)
addi r0, r0, 1
stb r0, 0x3(r30)  # add "fake" input to queue
SKIP:
