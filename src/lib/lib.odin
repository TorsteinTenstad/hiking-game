package lib

import "../common"
import "base:runtime"
import "core:strings"
import rl "vendor:raylib"

target: rl.Vector2 = rl.Vector2{0, 0}
speed: f32 = 0.2
player_action: PlayerAction = PlayerAction.Idle

status_happy: f32 = 1.0
status_food: f32 = 1.0
status_rest: f32 = 1.0

PlayerAction :: enum {
	Idle,
	Walking,
	Sleeping,
	Eating,
}

draw_status_bar :: proc(s: f32, rect: rl.Rectangle, color: rl.Color) {
	filled := rect
	filled.width *= s
	rl.DrawRectangleRec(filled, color)
}

@(export)
step: common.Step_Proc : proc "c" (state: ^common.State) {
	context = runtime.default_context()

	if (rl.IsMouseButtonDown(rl.MouseButton.LEFT)) {
		target = rl.GetMousePosition()
		player_action = PlayerAction.Walking
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE)) {
		player_action = PlayerAction.Idle
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.E)) {
		player_action = PlayerAction.Eating
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.S)) {
		player_action = PlayerAction.Sleeping
	}

	switch player_action {
	case .Idle:
	case .Walking:
		status_food -= 0.05 * rl.GetFrameTime()
		status_rest -= 0.05 * rl.GetFrameTime()

		delta := target - state.player_pos
		frame_speed := speed / rl.GetFrameTime()
		delta_length := rl.Vector2Length(delta)
		frame_step := frame_speed * (delta / delta_length)
		if (delta_length < frame_speed) {
			state.player_pos = target
			player_action = PlayerAction.Idle
		} else {
			state.player_pos += frame_step
		}
	case .Sleeping:
		status_rest += 0.05 * rl.GetFrameTime()
		if status_rest > 1.0 {
			status_rest = 1.0
			player_action = PlayerAction.Idle
		}
	case .Eating:
		status_food += 0.2 * rl.GetFrameTime()
		if status_food > 1.0 {
			status_food = 1.0
			player_action = PlayerAction.Idle
		}
	}

	rl.ClearBackground(rl.BLACK)


	rl.BeginShaderMode(state.map_shader)
	rl.DrawTexturePro(
		state.map_data_texture,
		rl.Rectangle{0, 0, f32(state.map_data_texture.width), f32(state.map_data_texture.height)},
		rl.Rectangle{0, 0, f32(common.screenWidth), f32(common.screenHeight)},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)
	rl.EndShaderMode()

	if (player_action == PlayerAction.Walking) {
		rl.DrawCircleV(target, 10, rl.YELLOW)
	}
	rl.DrawCircleV(state.player_pos, 5, rl.BLUE)

	draw_status_bar(status_happy, rl.Rectangle{x = 10, y = 10, width = 100, height = 20}, rl.GREEN)
	draw_status_bar(status_food, rl.Rectangle{x = 10, y = 40, width = 100, height = 20}, rl.RED)
	draw_status_bar(status_rest, rl.Rectangle{x = 10, y = 70, width = 100, height = 20}, rl.BROWN)

	action_string := "Unknown"
	switch player_action {
	case .Idle:
		action_string = "Idle"
	case .Walking:
		action_string = "Walking"
	case .Sleeping:
		action_string = "Sleeping"
	case .Eating:
		action_string = "Eating"
	}
	rl.DrawText(strings.clone_to_cstring(action_string), 400, 10, 16, rl.BLACK)
}
