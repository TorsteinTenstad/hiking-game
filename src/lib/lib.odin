#+vet explicit-allocators
package lib

import "../common"
import "base:runtime"
import "core:fmt"
import rl "vendor:raylib"

draw_float :: proc(value: f32, pos_x, pos_y: i32, font_size: i32, color: rl.Color) {
	N :: 6
	buf: [N]byte
	buf[N - 1] = 0
	text := fmt.bprintf(buf[:N - 1], "%.0f", value)
	rl.DrawText(cstring(&buf[0]), pos_x, pos_y, font_size, color)
}

draw_status_bar :: proc(s: f32, rect: rl.Rectangle, color: rl.Color) {
	filled := rect
	filled.width *= s
	rl.DrawRectangleRec(filled, color)
	draw_float(s * 100, i32(rect.x + rect.width + 10), i32(rect.y) + 5, 32, rl.WHITE)
}

player_action_to_string :: proc(a: common.PlayerAction) -> cstring {
	switch a {
	case .Idle:
		return "Idle"
	case .Walking:
		return "Walking"
	case .Sleeping:
		return "Sleeping"
	case .Eating:
		return "Eating"
	case .Fishing:
		return "Fishing"
	case .Gathering:
		return "Gathering"
	}
	return "Unknown"
}

point_is_masked :: proc(point: rl.Vector2, image: rl.Image) -> bool {
	x := i32(point.x)
	y := i32(point.y)
	in_bounds := 0 < x && x < image.width && 0 < y && y < image.height
	return in_bounds && rl.GetImageColor(image, x, y).r > 0
}

@(export)
step: common.Step_Proc : proc "c" (state: ^common.State) {
	context = runtime.default_context()

	terrain_camera := rl.Camera2D {
		zoom = f32(common.screenHeight) / f32(state.map_data_texture.width),
	}

	mouse_pos := rl.GetScreenToWorld2D(state.menu.pos, terrain_camera)
	fishing_enabled := point_is_masked(mouse_pos, state.bodies[0].mask_image)
	player_menu := rl.Vector2Distance(state.menu.pos, state.player_pos) < player_radius
	if (player_menu) {
		state.menu.pos = state.player_pos
	}
	terrain_menu := !player_menu
	hungry := state.status_food < 1.0

	menu_items: [6]MenuItem = {
		MenuItem {
			text = "Walk here",
			enabled = terrain_menu,
			on_click = proc(state: ^common.State) {
				state.target = state.menu.pos
				state.player_action = common.PlayerAction.Walking
			},
		},
		MenuItem {
			text = "   Sleep   ",
			enabled = player_menu,
			on_click = proc(state: ^common.State) {
				state.player_action = common.PlayerAction.Sleeping
			},
		},
		MenuItem {
			text = "Gather berries",
			enabled = player_menu,
			on_click = proc(state: ^common.State) {
				state.player_action = common.PlayerAction.Gathering
			},
		},
		MenuItem {
			text = "Go fishing",
			enabled = fishing_enabled && terrain_menu,
			on_click = proc(state: ^common.State) {
				state.player_action = common.PlayerAction.Fishing
			},
		},
		MenuItem {
			text = "Eat berries",
			enabled = state.berries > 0 && hungry && player_menu,
			on_click = proc(state: ^common.State) {
				state.berries -= 1.0
				state.status_food += 0.1
			},
		},
		MenuItem {
			text = "Eat fish",
			enabled = state.fish > 0 && hungry && player_menu,
			on_click = proc(state: ^common.State) {
				state.fish -= 1.0
				state.status_food += 0.3
			},
		},
	}

	in_menu := hovering_menu(&state.menu, menu_items[:])

	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE) || rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)) {
		state.player_action = common.PlayerAction.Idle
	}

	run_player_action(state)

	rl.ClearBackground(rl.BLACK)

	{
		rl.BeginMode2D(terrain_camera)
		defer rl.EndMode2D()
		{
			rl.BeginShaderMode(state.map_shader)
			defer rl.EndShaderMode()
			rl.DrawTextureV(state.map_data_texture, rl.Vector2{0, 0}, rl.WHITE)
		}
		mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), terrain_camera)
		for body in state.bodies {
			hovering := point_is_masked(mouse_pos, body.mask_image)
			if (hovering && !in_menu) {
				rl.DrawTextureV(body.texture, rl.Vector2{0, 0}, rl.Color{0, 121, 241, 100})
			}
		}
	}


	if (state.player_action == common.PlayerAction.Walking) {
		rl.DrawCircleV(state.target, 14, rl.YELLOW)
	}

	player_radius :: 10
	hovering_player := rl.Vector2Distance(rl.GetMousePosition(), state.player_pos) < player_radius
	if (hovering_player) {
		rl.DrawCircleV(state.player_pos, player_radius + 2, rl.WHITE)
	}
	rl.DrawCircleV(state.player_pos, player_radius, rl.BLUE)


	draw_status_bar(
		state.status_happy,
		rl.Rectangle{x = 810, y = 300, width = 200, height = 40},
		rl.GREEN,
	)
	draw_status_bar(
		state.status_food,
		rl.Rectangle{x = 810, y = 350, width = 200, height = 40},
		rl.RED,
	)
	draw_status_bar(
		state.status_rest,
		rl.Rectangle{x = 810, y = 400, width = 200, height = 40},
		rl.BROWN,
	)

	rl.DrawText(player_action_to_string(state.player_action), 950, 250, 36, rl.WHITE)

	rl.DrawTexture(state.sprites.berries, 820, 500, rl.WHITE)
	rl.DrawTexture(state.sprites.fish, 810, 620, rl.WHITE)

	draw_float(state.berries, 950, 520, 64, rl.WHITE)
	draw_float(state.fish, 950, 620, 64, rl.WHITE)


	run_menu(state, &state.menu, menu_items[:], rl.GetMousePosition().x < 800)
}
