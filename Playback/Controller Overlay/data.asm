DATA_LOC:
blrl
.set FLOAT_ZERO, 0
.float 0.0
.set BG_X, FLOAT_ZERO + 4
.float 1
.set BG_Y, BG_X + 4
.float -29
.set BG_WIDTH, BG_Y + 4
.float 2
.set BG_HEIGHT, BG_WIDTH + 4
.float 1.95
.set BG_OPACITY, BG_HEIGHT + 4
.float 0.7
.set BG_COLOR, BG_OPACITY + 4
.byte 0,0,0,255

MAIN_STICK_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.1
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float -3
.set TEXT_Y, TEXT_X + 4
.float 20.5
.set MOVE_SCALE, TEXT_Y + 4
.float 1.0
.set TEXT, MOVE_SCALE + 4
.string "."
.align 2

C_STICK_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.1
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 0
.set TEXT_Y, TEXT_X + 4
.float 20.5
.set MOVE_SCALE, TEXT_Y + 4
.float 1
.set TEXT, MOVE_SCALE + 4
.string "."
.align 2

A_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.04
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 4.5
.set TEXT_Y, TEXT_X + 4
.float 22.5
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "A"
.align 2

B_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.03
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 3
.set TEXT_Y, TEXT_X + 4
.float 23
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "B"
.align 2

X_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.03
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 5.5
.set TEXT_Y, TEXT_X + 4
.float 21.5
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "x"
.align 2

Y_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.03
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 4.5
.set TEXT_Y, TEXT_X + 4
.float 21
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "y"
.align 2

L_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.03
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float -3
.set TEXT_Y, TEXT_X + 4
.float 21.5
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "L"
.align 2

R_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.03
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 0
.set TEXT_Y, TEXT_X + 4
.float 21.5
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "R"
.align 2

Z_BTN_LOC:
blrl
.set TEXT_CANVAS_SCALE, 0
.float 0.03
.set TEXT_X, TEXT_CANVAS_SCALE + 4
.float 2
.set TEXT_Y, TEXT_X + 4
.float 21.5
.set MOVE_SCALE, TEXT_Y + 4
.float 0.5
.set TEXT, MOVE_SCALE + 4
.string "Z"
.align 2
