package common

import rl "vendor:raylib"

screenWidth :: 1200
screenHeight :: 800

Sprites :: struct {
	berries: rl.Texture2D,
	fish:    rl.Texture2D,
}

TerrainBody :: struct {
	mask_image: rl.Image,
	texture:    rl.Texture2D,
}

PlayerAction :: enum {
	Idle,
	Walking,
	Sleeping,
	Eating,
	Fishing,
	Gathering,
}


State :: struct {
	player_pos:       rl.Vector2,
	map_shader:       rl.Shader,
	map_data_image:   rl.Image,
	map_data_texture: rl.Texture2D,
	sprites:          Sprites,
	water0:           TerrainBody,
	target:           rl.Vector2,
	player_action:    PlayerAction,
	fish:             f32,
	berries:          f32,
	status_happy:     f32,
	status_food:      f32,
	status_rest:      f32,
}

Step_Proc :: #type proc "c" (state: ^State)
