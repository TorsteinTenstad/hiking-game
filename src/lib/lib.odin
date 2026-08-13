package lib

import "../common"
import "vendor:raylib"

@(export)
step: common.Step_Proc : proc "c" (state: ^common.State) {

	if (raylib.IsMouseButtonDown(raylib.MouseButton.LEFT)) {
		state.player_pos = raylib.GetMousePosition()
	}

	raylib.DrawCircleV(state.player_pos, 10, raylib.RED)
}
