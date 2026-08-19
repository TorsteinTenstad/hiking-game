package main

import "../common"
import rl "vendor:raylib"

Sprite :: enum {
	Fish,
	Berries,
}

sprite_filename :: proc(sprite: Sprite) -> string {
	switch (sprite) {
	case .Fish:
		return "fish.png"
	case .Berries:
		return "berries.png"
	}
	return ""
}

init :: proc(state: ^common.State) {
	state.status_happy = 1.0
	state.status_food = 1.0
	state.status_rest = 1.0
	state.player_pos = {350, 280}

	state.map_data_image = rl.LoadImage("resources/map_data.png")
	state.map_data_texture = rl.LoadTextureFromImage(state.map_data_image)

	state.bodies[0].mask_image = rl.LoadImage("resources/water0.png")
	state.bodies[0].texture = rl.LoadTextureFromImage(state.bodies[0].mask_image)

	state.sprites.berries = rl.LoadTexture("resources/berries.png")
	state.sprites.fish = rl.LoadTexture("resources/fish.png")
}

deinit :: proc(state: ^common.State) {
	rl.UnloadImage(state.map_data_image)
	rl.UnloadTexture(state.map_data_texture)

	for body in state.bodies {
		rl.UnloadImage(body.mask_image)
		rl.UnloadTexture(body.texture)
	}

	rl.UnloadTexture(state.sprites.berries)
	rl.UnloadTexture(state.sprites.fish)
}
