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
	state.map_data_image = rl.LoadImage("resources/map_data.png")
	state.map_data_texture = rl.LoadTextureFromImage(state.map_data_image)

	state.sprites.berries = rl.LoadTexture("resources/berries.png")
	state.sprites.fish = rl.LoadTexture("resources/fish.png")
}

deinit :: proc(state: ^common.State) {
	rl.UnloadImage(state.map_data_image)
	rl.UnloadTexture(state.map_data_texture)

	rl.UnloadTexture(state.sprites.berries)
	rl.UnloadTexture(state.sprites.fish)
}
