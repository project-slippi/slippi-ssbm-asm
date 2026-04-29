################################################################################
# Address: 0x8017a890
# mex injections are scattered throughout the character scale table
# for the results screen. This just moves that table into gecko space.
################################################################################

b CODE_START

RESULTS_SCALE_TABLE_BLRL:
blrl
# 26 entries
.float 0.85
.float 0.8
.float 1.0
.float 1.0
.float 1.0
.float 0.69999999
.float 0.89999998
.float 1.0
.float 1.0
.float 0.88
.float 0.8
.float 1.0
.float 0.89999998
.float 1.0
.float 0.89999998
.float 1.0
.float 0.89999998
.float 0.89999998
.float 0.89999998
.float 0.89999998
.float 1.0
.float 1.0
.float 1.0
.float 1.0
.float 1.0
.float 0.79 

CODE_START:

  bl RESULTS_SCALE_TABLE_BLRL
  mflr r0

EXIT: