package main

import "core:dynlib"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

HotreloadProc :: struct {
	path:       string,
	symbol:     string,
	proc_found: bool,
	last_load:  i32,
	lib:        dynlib.Library,
	lib_loaded: bool,
	proc_ptr:   rawptr,
}

init_hotreload_proc :: proc(path: string, symbol: string) -> HotreloadProc {
	return HotreloadProc{path = path, symbol = symbol}
}

hotreload :: proc(l: ^HotreloadProc) {
	fileModTime := rl.GetFileModTime(strings.clone_to_cstring(l.path))
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
		return
	}

	state, wait_err := os.process_wait(process)
	if wait_err != nil {
		fmt.eprintln("failed waiting for build:", wait_err)
		return
	}

	if state.exit_code != 0 {
		fmt.eprintln("building", l.path, "failed with exit code", state.exit_code)
		return
	}

	unload_hotreload_proc(l)
	l.lib, l.lib_loaded = dynlib.load_library(lib_path)
	if !l.lib_loaded {
		fmt.println("failed to load", lib_path)
		return
	}
	l.proc_ptr, l.proc_found = dynlib.symbol_address(l.lib, l.symbol)
	if !l.proc_found {
		fmt.println("symbol", l.symbol, "not found in ")
		return
	}
}

unload_hotreload_proc :: proc(l: ^HotreloadProc) {
	if (l.lib_loaded) {
		dynlib.unload_library(l.lib)
	}
}
