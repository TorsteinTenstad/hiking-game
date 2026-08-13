package main

import "../common"
import rl "vendor:raylib"

init :: proc(state: ^common.State) {
    mapDataImagePath :: "resources/map_data.png"
	
	state.map_data_image = rl.LoadImage(mapDataImagePath)
	state.map_data_texture = rl.LoadTextureFromImage(state.map_data_image)
}

deinit ::proc(state: ^common.State) {
    rl.UnloadImage(state.map_data_image)
    rl.UnloadTexture(state.map_data_texture)
}