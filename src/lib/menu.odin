#+vet explicit-allocators
package lib

import "../common"
import "core:math"

import rl "vendor:raylib"

MenuItem :: struct {
	text:     cstring,
	enabled:  bool,
	on_click: proc(state: ^common.State),
}

point_size: i32 : 10
text_margin: f32 : 10
button_margin: f32 : 10
font_size: i32 : 32

point_size_f :: f32(point_size)
font_size_f :: f32(font_size)

hovering_menu :: proc(menu: ^common.Menu, items: []MenuItem) -> bool {
	menu_rect, _ := menu_size(menu, items)
	return menu.open && rl.CheckCollisionPointRec(rl.GetMousePosition(), menu_rect)
}

menu_size :: proc(menu: ^common.Menu, items: []MenuItem) -> (rl.Rectangle, i32) {
	max_text_width: i32 = 0
	n: i32 = 0
	for item in items {
		if !item.enabled {
			continue
		}
		max_text_width = math.max(max_text_width, rl.MeasureText(item.text, font_size))
		n += 1

	}
	n_f := f32(n)
	height := n_f * font_size_f + 2 * n_f * text_margin + (n_f + 1) * button_margin
	width := f32(max_text_width) + 2 * text_margin + 2 * button_margin
	x := menu.pos.x - width / 2
	y := menu.pos.y + point_size_f
	return rl.Rectangle{height = height, width = width, x = x, y = y}, max_text_width
}

run_menu :: proc(
	state: ^common.State,
	menu: ^common.Menu,
	items: []MenuItem,
	can_open: bool,
) -> (
	int,
	bool,
) {

	if (menu.open && rl.IsMouseButtonReleased(rl.MouseButton.RIGHT)) {
		menu.open = false
	}
	if (!menu.open && rl.IsMouseButtonReleased(rl.MouseButton.LEFT) && can_open) {
		menu.open = true
		menu.pos = rl.GetMousePosition()
		return 0, false
	}
	if (!menu.open) {
		return 0, false
	}

	rect, max_text_width := menu_size(menu, items)
	rl.DrawRectangleRec(rect, rl.WHITE)
	rl.DrawTriangle(
		menu.pos,
		menu.pos + rl.Vector2{-point_size_f, point_size_f},
		menu.pos + rl.Vector2{point_size_f, point_size_f},
		rl.WHITE,
	)
	y := f32(rect.y)
	clicked_item := 0
	clicked := false
	for item, idx in items {
		if !item.enabled {
			continue
		}
		text_width := rl.MeasureText(item.text, font_size)
		y += button_margin
		button_rect := rl.Rectangle {
			x      = rect.x + button_margin,
			y      = y,
			width  = f32(max_text_width) + 2 * text_margin,
			height = font_size_f + 2 * text_margin,
		}
		button_hover := rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rect)
		button_clicked := button_hover && rl.IsMouseButtonReleased(rl.MouseButton.LEFT)
		if (button_clicked) {
			item.on_click(state)
			clicked = true
			clicked_item = idx
		}

		button_color := button_hover ? rl.YELLOW : rl.GOLD
		rl.DrawRectangleRec(button_rect, button_color)
		y += text_margin
		rl.DrawText(
			item.text,
			i32(rect.x + rect.width / 2) - text_width / 2,
			i32(y),
			font_size,
			rl.RED,
		)
		y += font_size_f + text_margin
	}
	if (!clicked && rl.IsMouseButtonReleased(rl.MouseButton.LEFT) && can_open) {
		menu.open = true
		menu.pos = rl.GetMousePosition()
	}
	if (clicked) {
		menu.open = false
	}
	return clicked_item, clicked
}
