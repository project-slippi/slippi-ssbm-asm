################################################################################
# Address: 0x801a40e8
################################################################################
# This will run after every scene change, and after the scene has loaded.
#
# Example Report:
# [lbHeap] -- Report --
#      Hsd :   905 KB +   5010 KB(  5131200) /  5916 KB
#     ARAM :     0 KB +    422 KB(   432480) /   422 KB
#      Seq :     1 KB +      0 KB(      896) /     2 KB
#     Stay :  5089 KB +      0 KB(      960) /  5090 KB
#     AllM :  1094 KB +   5350 KB(  5478464) /  6445 KB
#     AllA :  2603 KB +   7046 KB(  7215648) /  9650 KB
# MainRAM Total : 17453 KB( 17872032)
#    ARAM Total : 10072 KB( 10314080)
#
#   heap or handle name : free space + used space (bytes) / total space
################################################################################

.include "Common/Common.s"

CODE_START:
  backup

  branchl r12, 0x80015df8 # HSD_CheckHeap

EXIT:
  restore
  lwz	r3, 0x0004 (r26)
