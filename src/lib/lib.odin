package lib

import "../common"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

speed: f32 = 0.02


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

MenuItem :: struct {
	text: string,
}

Menu :: struct {
	pos:   rl.Vector2,
	items: [dynamic; 8]MenuItem,
}

run_menu :: proc(menu: ^Menu) -> (int, bool) {
	point_size: i32 = 10
	point_size_f := f32(point_size)
	text_margin: i32 = 10
	button_margin: i32 = 10
	font_size: i32 = 32

	max_text_width: i32 = 0
	for item in menu.items {
		chars := strings.clone_to_cstring(item.text)
		max_text_width = math.max(max_text_width, rl.MeasureText(chars, font_size))
	}
	n := i32(len(menu.items))
	rect_height := n * font_size + 2 * n * text_margin + (n + 1) * button_margin
	rect_width := max_text_width + 2 * text_margin + 2 * button_margin

	rect_x := i32(menu.pos.x) - rect_width / 2
	rect_y := i32(menu.pos.y) + point_size

	rl.DrawRectangle(rect_x, rect_y, rect_width, rect_height, rl.WHITE)
	rl.DrawTriangle(
		menu.pos,
		menu.pos + rl.Vector2{-point_size_f, point_size_f},
		menu.pos + rl.Vector2{point_size_f, point_size_f},
		rl.WHITE,
	)
	y := rect_y
	clicked_item := 0
	clicked := false
	for item, idx in menu.items {
		chars := strings.clone_to_cstring(item.text)
		text_width := rl.MeasureText(chars, font_size)
		y += button_margin
		button_rect := rl.Rectangle {
			x      = f32(rect_x + button_margin),
			y      = f32(y),
			width  = f32(max_text_width + 2 * text_margin),
			height = f32(font_size + 2 * text_margin),
		}
		button_hover := rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rect)
		button_clicked := button_hover && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
		if (button_clicked) {
			clicked = true
			clicked_item = idx
		}

		button_color := button_hover ? rl.YELLOW : rl.GOLD
		rl.DrawRectangleRec(button_rect, button_color)
		y += text_margin
		rl.DrawText(chars, rect_x + rect_width / 2 - text_width / 2, i32(y), font_size, rl.RED)
		y += font_size + text_margin
	}
	return clicked_item, clicked
}


menu_open := false
menu_pos := rl.Vector2{900, 10}

@(export)
step: common.Step_Proc : proc "c" (state: ^common.State) {
	context = runtime.default_context()

	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE) || rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)) {
		state.player_action = common.PlayerAction.Idle
	}

	switch state.player_action {
	case .Idle:
	case .Walking:
		state.status_food -= 0.05 * rl.GetFrameTime()
		state.status_rest -= 0.04 * rl.GetFrameTime()

		delta := state.target - state.player_pos
		frame_speed := speed / rl.GetFrameTime()
		delta_length := rl.Vector2Length(delta)
		frame_step := frame_speed * (delta / delta_length)
		if (delta_length < frame_speed) {
			state.player_pos = state.target
			state.player_action = common.PlayerAction.Idle
		} else {
			state.player_pos += frame_step
		}
	case .Sleeping:
		state.status_rest += 0.05 * rl.GetFrameTime()
		if state.status_rest > 1.0 {
			state.status_rest = 1.0
			state.player_action = common.PlayerAction.Idle
		}
	case .Eating:
		state.status_food += 0.2 * rl.GetFrameTime()
		if state.status_food > 1.0 {
			state.status_food = 1.0
			state.player_action = common.PlayerAction.Idle
		}
	case .Fishing:
		state.fish += 0.2 * rl.GetFrameTime()
	case .Gathering:
		state.berries += 0.6 * rl.GetFrameTime()
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

	mouse_pos := rl.GetMousePosition()
	image_x := state.map_data_texture.width * i32(mouse_pos.x) / common.screenHeight
	image_y := state.map_data_texture.height * i32(mouse_pos.y) / common.screenHeight
	in_bounds :=
		image_x < state.water0.mask_image.width && image_y < state.water0.mask_image.height
	water0_hovered :=
		in_bounds && rl.GetImageColor(state.water0.mask_image, image_x, image_y).r > 0
	if (water0_hovered) {
		rl.DrawTexturePro(
			state.water0.texture,
			rl.Rectangle {
				0,
				0,
				f32(state.map_data_texture.width),
				f32(state.map_data_texture.height),
			},
			rl.Rectangle{0, 0, f32(common.screenHeight), f32(common.screenHeight)},
			rl.Vector2{0, 0},
			0,
			rl.Color{0, 121, 241, 100},
		)
	}

	if (state.player_action == common.PlayerAction.Walking) {
		rl.DrawCircleV(state.target, 10, rl.YELLOW)
	}
	rl.DrawCircleV(state.player_pos, 5, rl.BLUE)

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

	action_string := "Unknown"
	switch state.player_action {
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
	if (fish_clicked && state.status_food < 1.0) {
		state.fish -= 1.0
		state.status_food = math.min(1.0, state.status_food + 0.3)
	}
	if (berries_clicked && state.status_food < 1.0) {
		state.berries -= 1.0
		state.status_food = math.min(1.0, state.status_food + 0.1)
	}

	rl.DrawText(
		strings.clone_to_cstring(fmt.tprintf("%0.f", state.berries)),
		950,
		520,
		64,
		rl.WHITE,
	)
	rl.DrawText(strings.clone_to_cstring(fmt.tprintf("%0.f", state.fish)), 950, 620, 64, rl.WHITE)


	if (menu_open) {
		if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
			menu_open = false
		}
		menu := Menu {
			pos = menu_pos,
		}
		append(&menu.items, MenuItem{text = "Walk here"})
		append(&menu.items, MenuItem{text = "Sleep"})
		append(&menu.items, MenuItem{text = "Gather berries"})

		image_x := state.map_data_texture.width * i32(menu_pos.x) / common.screenHeight
		image_y := state.map_data_texture.height * i32(menu_pos.y) / common.screenHeight
		in_bounds :=
			image_x < state.water0.mask_image.width && image_y < state.water0.mask_image.height
		fishing_enabled :=
			in_bounds && rl.GetImageColor(state.water0.mask_image, image_x, image_y).r > 0
		if (fishing_enabled) {
			append(&menu.items, MenuItem{text = "Go fishing"})
		}
		if (state.berries > 0) {
			append(&menu.items, MenuItem{text = "Eat berries"})
		}
		if (state.fish > 0) {
			append(&menu.items, MenuItem{text = "Eat fish"})
		}

		clicked_index, clicked := run_menu(&menu)
		if (clicked) {
			menu_open = false

			if (clicked_index == 0 && rl.GetMousePosition().x < 800) {
				state.target = rl.GetMousePosition()
				state.player_action = common.PlayerAction.Walking
			} else if (clicked_index == 1) {
				state.player_action = common.PlayerAction.Sleeping
			} else if (clicked_index == 2) {
				state.player_action = common.PlayerAction.Gathering
			} else if (clicked_index == 3) {
				state.player_action = common.PlayerAction.Fishing
			}
		}
	}
	if (rl.IsMouseButtonPressed(rl.MouseButton.RIGHT)) {
		menu_open = true
		menu_pos = rl.GetMousePosition()
	}
}
