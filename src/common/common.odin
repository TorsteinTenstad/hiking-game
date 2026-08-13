package common

import rl "vendor:raylib"

screenWidth :: 1200
screenHeight :: 800

Sprites :: struct {
	berries: rl.Texture2D,
	fish: rl.Texture2D,
}

State :: struct {
	player_pos:       rl.Vector2,
	map_shader:       rl.Shader,
	map_data_image:   rl.Image,
	map_data_texture: rl.Texture2D,
	sprites:   Sprites,
}

Step_Proc :: #type proc "c" (state: ^State)
