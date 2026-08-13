package common

import rl "vendor:raylib"

screenWidth :: 800
screenHeight :: 800

State :: struct {
	player_pos:       rl.Vector2,
	map_shader:       rl.Shader,
	map_data_image:   rl.Image,
	map_data_texture: rl.Texture2D,
}

Step_Proc :: #type proc "c" (state: ^State)
