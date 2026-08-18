#+vet explicit-allocators
package lib

import "../common"
import rl "vendor:raylib"

speed: f32 = 0.02

run_player_action :: proc(state: ^common.State) {
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
}
