package common

import "vendor:raylib"

State :: struct {
	player_pos: raylib.Vector2,
}

Step_Proc :: #type proc "c" (state: ^State)
