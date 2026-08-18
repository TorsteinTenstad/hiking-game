#+vet explicit-allocators
package lib

import "../common"
import "core:math"

import rl "vendor:raylib"

MenuItem :: struct {
	text:    cstring,
	enabled: bool,
}

run_menu :: proc(menu: ^common.Menu, items: []MenuItem) -> (int, bool) {
	point_size: i32 = 10
	point_size_f := f32(point_size)
	text_margin: i32 = 10
	button_margin: i32 = 10
	font_size: i32 = 32

	if (menu.open && rl.IsMouseButtonPressed(rl.MouseButton.RIGHT)) {
		menu.open = false
	}
	if (!menu.open && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
		menu.open = true
		menu.pos = rl.GetMousePosition()
	}
	if (!menu.open) {
		return 0, false
	}

	max_text_width: i32 = 0
	n: i32 = 0
	for item in items {
		if !item.enabled {
			continue
		}
		max_text_width = math.max(max_text_width, rl.MeasureText(item.text, font_size))
		n += 1

	}
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
	for item, idx in items {
		if !item.enabled {
			continue
		}
		text_width := rl.MeasureText(item.text, font_size)
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
		rl.DrawText(item.text, rect_x + rect_width / 2 - text_width / 2, i32(y), font_size, rl.RED)
		y += font_size + text_margin
	}
	if (!clicked && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
		menu.open = true
		menu.pos = rl.GetMousePosition()
	}
	if (clicked) {
		menu.open = false
	}
	return clicked_item, clicked
}
