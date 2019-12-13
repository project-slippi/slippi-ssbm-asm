################################################################################
# Address: 80377544
################################################################################

# Credit to tauKhan

# If we are iterating without anything in the input buffer, move the pad input
# along so that we correctly restore the x analog value used by UCF to the
# correct place. Previously, there was a possibility for desyncs when doing a
# UCF dashback while in FFW.
#
# I believe the only time this would *not* skip is when we force a FFW.
# Skip if the input buffer is larger than zero (unused inputs are present).

bne+ SKIP

# Add "fake" input to the queue
li r0, 1
stb r0, 0x3(r30)

SKIP:
