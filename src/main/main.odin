package main

import "../common"
import "core:dynlib"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor:raylib"

Square_Proc :: proc "c" (x: i32) -> i32

HotreloadProc :: struct {
	path:       string,
	symbol:     string,
	last_load:  i32,
	lib:        dynlib.Library,
	lib_loaded: bool,
	proc_ptr:   rawptr,
}

init_hotreload_proc :: proc(path: string, symbol: string) -> HotreloadProc {
	return HotreloadProc{path = path, symbol = symbol}
}

hotreload :: proc(l: ^HotreloadProc) {
	
	fileModTime := raylib.GetFileModTime(strings.clone_to_cstring(l.path))
	os.make_directory_all("build/hotreloading")
	lib_path := fmt.tprintf("build/hotreloading/lib_%d.dll", fileModTime)
	if (l.last_load == fileModTime) {
		return
	}
	l.last_load = fileModTime

	process, err := os.process_start(
		{
			command = {
				"odin",
				"build",
				l.path,
				"-file",
				"-build-mode:dll",
				fmt.tprintf("-out:%s", lib_path),
				"-define:RAYLIB_SHARED=true",
			},
		},
	)
	if err != nil {
		fmt.eprintln("failed to start build:", err)
	}

	state, wait_err := os.process_wait(process)
	if wait_err != nil {
		fmt.eprintln("failed waiting for build:", wait_err)
	}

	if state.exit_code != 0 {
		fmt.eprintln("building", l.path, "failed with exit code", state.exit_code)
	}

	unload_hotreload_proc(l)
	l.lib, l.lib_loaded = dynlib.load_library(lib_path)
	if !l.lib_loaded {
		fmt.println("failed to load library")
	}
	proc_ptr, proc_found := dynlib.symbol_address(l.lib, l.symbol)
	if !proc_found {
		fmt.println("symbol not found")
	}
	l.proc_ptr = proc_ptr
}

unload_hotreload_proc :: proc(l: ^HotreloadProc) {
	if (l.lib_loaded) {
		defer dynlib.unload_library(l.lib)
	}
}

main :: proc() {
	raylib.SetTraceLogLevel(raylib.TraceLogLevel.WARNING)

	screenWidth :: 1200
	screenHeight :: 1200

	fragShaderSourcePath :: "resources/shaders/map.frag"
	vertShaderSourcePath :: "resources/shaders/map.vert"
	libSourcePath :: "src/lib/lib.odin"
	mapDataImagePath :: "resources/map_data.png"

	state: common.State

	step_proc: HotreloadProc = init_hotreload_proc("src/lib/lib.odin", "step")
	hotreload(&step_proc)
	defer unload_hotreload_proc(&step_proc)

	shaderLoadTime := raylib.GetFileModTime(fragShaderSourcePath)
	player_pos := raylib.GetMousePosition()

	raylib.InitWindow(screenWidth, screenHeight, "hiking-game")
	defer raylib.CloseWindow()

	img := raylib.LoadImage(mapDataImagePath)
	defer raylib.UnloadImage(img)

	texture := raylib.LoadTextureFromImage(img)
	defer raylib.UnloadTexture(texture)

	shader := raylib.LoadShader(vertShaderSourcePath, fragShaderSourcePath)
	defer raylib.UnloadShader(shader)

	for !raylib.WindowShouldClose() {
		hotreload(&step_proc)
		latestEdit := raylib.GetFileModTime(fragShaderSourcePath)
		if (shaderLoadTime < latestEdit) {
			raylib.UnloadShader(shader)
			shader = raylib.LoadShader(vertShaderSourcePath, fragShaderSourcePath)
			shaderLoadTime = latestEdit
		}

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(raylib.BLACK)


		raylib.BeginShaderMode(shader)
		raylib.DrawTexturePro(
			texture,
			raylib.Rectangle{0, 0, f32(texture.width), f32(texture.height)},
			raylib.Rectangle{0, 0, f32(screenWidth), f32(screenHeight)},
			raylib.Vector2{0, 0},
			0,
			raylib.WHITE,
		)
		raylib.EndShaderMode()

		step: common.Step_Proc = cast(common.Step_Proc)step_proc.proc_ptr
		step(&state)
	}

}
