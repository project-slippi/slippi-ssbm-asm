# Address: 80359740

addi r30, r3, 0

lwz r12, -0x4158(r13)

cmplwi r12, 0
beq end

mtspr lr, r12
blrl

end: