#+vet explicit-allocators
package main

import "../common"
import "core:fmt"
import rl "vendor:raylib"

Square_Proc :: proc "c" (x: i32) -> i32

main :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)

	fragShaderSourcePath :: "resources/shaders/map.frag"
	vertShaderSourcePath :: "resources/shaders/map.vert"
	libSourcePath :: "src/lib/lib.odin"

	step_proc: HotreloadProc = init_hotreload_proc("src/lib/", "step")
	hotreload(&step_proc)
	if (!step_proc.proc_found) {
		fmt.println("step proc not found")
		return
	}

	rl.InitWindow(common.screenWidth, common.screenHeight, "hiking-game")
	defer rl.CloseWindow()

	state: common.State
	init(&state)
	defer deinit(&state)

	defer unload_hotreload_proc(&step_proc)

	shaderLoadTime := rl.GetFileModTime(fragShaderSourcePath)
	state.map_shader = rl.LoadShader(vertShaderSourcePath, fragShaderSourcePath)
	defer rl.UnloadShader(state.map_shader)

	rl.SetTargetFPS(30)

	for !rl.WindowShouldClose() {
		hotreload(&step_proc)

		latestEdit := rl.GetFileModTime(fragShaderSourcePath)
		if (shaderLoadTime < latestEdit) {
			shaderLoadTime = latestEdit
			new_shader := rl.LoadShader(vertShaderSourcePath, fragShaderSourcePath)
			if rl.IsShaderValid(new_shader) {
				rl.UnloadShader(state.map_shader)
				state.map_shader = new_shader
			}
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		step: common.Step_Proc = cast(common.Step_Proc)step_proc.proc_ptr
		step(&state)
	}

}
