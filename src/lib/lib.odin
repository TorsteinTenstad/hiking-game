package lib

import "../common"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

target: rl.Vector2 = rl.Vector2{0, 0}
speed: f32 = 0.02
player_action: PlayerAction = PlayerAction.Idle

fish: f32 = 0
berries: f32 = 0

status_happy: f32 = 1.0
status_food: f32 = 1.0
status_rest: f32 = 1.0

PlayerAction :: enum {
	Idle,
	Walking,
	Sleeping,
	Eating,
	Fishing,
	Gathering,
}

draw_status_bar :: proc(s: f32, rect: rl.Rectangle, color: rl.Color) {
	filled := rect
	filled.width *= s
	rl.DrawRectangleRec(filled, color)
	t := fmt.tprintf("%.0f", s * 100)
	rl.DrawText(
		strings.clone_to_cstring(t),
		i32(rect.x + rect.width + 10),
		i32(rect.y) + 5,
		32,
		rl.WHITE,
	)
}

@(export)
step: common.Step_Proc : proc "c" (state: ^common.State) {
	context = runtime.default_context()

	if (rl.IsMouseButtonDown(rl.MouseButton.LEFT) && rl.GetMousePosition().x < 800) {
		target = rl.GetMousePosition()
		player_action = PlayerAction.Walking
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE)) {
		player_action = PlayerAction.Idle
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.F)) {
		player_action = PlayerAction.Fishing
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.G)) {
		player_action = PlayerAction.Gathering
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.S)) {
		player_action = PlayerAction.Sleeping
	}

	switch player_action {
	case .Idle:
	case .Walking:
		status_food -= 0.05 * rl.GetFrameTime()
		status_rest -= 0.04 * rl.GetFrameTime()

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
	case .Fishing:
		fish += 0.2 * rl.GetFrameTime()
	case .Gathering:
		berries += 0.6 * rl.GetFrameTime()
	}

	rl.ClearBackground(rl.BLACK)


	rl.BeginShaderMode(state.map_shader)
	rl.DrawTexturePro(
		state.map_data_texture,
		rl.Rectangle{0, 0, f32(state.map_data_texture.width), f32(state.map_data_texture.height)},
		rl.Rectangle{0, 0, f32(common.screenHeight), f32(common.screenHeight)},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)
	rl.EndShaderMode()

	if (player_action == PlayerAction.Walking) {
		rl.DrawCircleV(target, 10, rl.YELLOW)
	}
	rl.DrawCircleV(state.player_pos, 5, rl.BLUE)

	draw_status_bar(
		status_happy,
		rl.Rectangle{x = 810, y = 300, width = 200, height = 40},
		rl.GREEN,
	)
	draw_status_bar(status_food, rl.Rectangle{x = 810, y = 350, width = 200, height = 40}, rl.RED)
	draw_status_bar(
		status_rest,
		rl.Rectangle{x = 810, y = 400, width = 200, height = 40},
		rl.BROWN,
	)

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
	case .Fishing:
		action_string = "Fishing"
	case .Gathering:
		action_string = "Gathering"
	}
	rl.DrawText(strings.clone_to_cstring(action_string), 950, 250, 36, rl.WHITE)

	berries_hovered := rl.CheckCollisionPointRec(
		rl.GetMousePosition(),
		rl.Rectangle{x = 820, y = 500, width = 96, height = 96},
	)
	fish_hovered := rl.CheckCollisionPointRec(
		rl.GetMousePosition(),
		rl.Rectangle{x = 820, y = 600, width = 96, height = 96},
	)
	rl.DrawTexture(state.sprites.berries, 820, 500, berries_hovered ? rl.WHITE : rl.GRAY)
	rl.DrawTexture(state.sprites.fish, 810, 620, fish_hovered ? rl.WHITE : rl.GRAY)
	berries_clicked := berries_hovered && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
	fish_clicked := fish_hovered && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
	if (fish_clicked && status_food < 1.0) {
		fish -= 1.0
		status_food = math.max(1.0, status_food + 0.3)
	}
	if (berries_clicked && status_food < 1.0) {
		berries -= 1.0
		status_food = math.max(1.0, status_food + 0.1)
	}

	rl.DrawText(strings.clone_to_cstring(fmt.tprintf("%0.f", berries)), 950, 520, 64, rl.WHITE)
	rl.DrawText(strings.clone_to_cstring(fmt.tprintf("%0.f", fish)), 950, 620, 64, rl.WHITE)
}
