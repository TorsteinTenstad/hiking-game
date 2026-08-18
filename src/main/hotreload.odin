package main

import "core:dynlib"
import "core:fmt"
import "core:math"
import "core:os"
import "core:time"

HotreloadProc :: struct {
	path:       string,
	symbol:     string,
	proc_found: bool,
	last_load:  i64,
	lib:        dynlib.Library,
	lib_loaded: bool,
	proc_ptr:   rawptr,
}

init_hotreload_proc :: proc(path: string, symbol: string) -> HotreloadProc {
	return HotreloadProc{path = path, symbol = symbol}
}

hotreload :: proc(l: ^HotreloadProc) {
	infos, read_dir_err := os.read_all_directory_by_path(l.path, context.allocator)
	if read_dir_err != nil {
		fmt.println("failed to read directory:", read_dir_err)
		return
	}
	defer os.file_info_slice_delete(infos, context.allocator)
	max_mod_time_unix: i64 = 0
	for info in infos {
		mod_time_unix := time.to_unix_seconds(info.modification_time)
		max_mod_time_unix = math.max(max_mod_time_unix, mod_time_unix)
	}

	if (l.last_load == max_mod_time_unix) {
		return
	}
	l.last_load = max_mod_time_unix

	os.make_directory_all("build/hotreloading")
	lib_path := fmt.tprintf("build/hotreloading/lib_%d.dll", max_mod_time_unix)
	process, err := os.process_start(
		{
			command = {
				"odin",
				"build",
				l.path,
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
		fmt.eprintln(
			"building",
			l.path,
			"into",
			lib_path,
			"failed with exit code",
			state.exit_code,
		)
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
